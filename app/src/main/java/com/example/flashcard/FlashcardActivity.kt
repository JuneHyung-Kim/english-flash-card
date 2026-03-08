package com.example.flashcard

import android.os.Bundle
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import org.json.JSONArray
import kotlin.math.abs

data class Flashcard(val ko: String, val en: String)

class FlashcardActivity : AppCompatActivity() {

    private val cards = mutableListOf<Flashcard>()
    private var currentIndex = 0
    private lateinit var gestureDetector: GestureDetector
    private lateinit var bookmarked: MutableSet<String>
    private lateinit var excluded: MutableSet<String>

    companion object {
        const val EXTRA_MODE = "mode"
        const val MODE_BOOKMARKED = "bookmarked"
        const val MODE_USER = "user"
        private const val PREFS = "flashcard_prefs"
        private const val KEY_BOOKMARKED = "bookmarked"
        const val KEY_EXCLUDED = "excluded"
        private fun progressIndexKey(mode: String?) = "progress_index_${mode ?: "default"}"
        private fun progressOrderKey(mode: String?) = "progress_order_${mode ?: "default"}"
    }

    private var mode: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_flashcard)

        val prefs = getSharedPreferences(PREFS, MODE_PRIVATE)
        bookmarked = (prefs.getStringSet(KEY_BOOKMARKED, emptySet()) ?: emptySet()).toMutableSet()
        excluded = (prefs.getStringSet(KEY_EXCLUDED, emptySet()) ?: emptySet()).toMutableSet()

        mode = intent.getStringExtra(EXTRA_MODE)
        loadCards(mode)

        if (cards.isEmpty()) {
            Toast.makeText(this, "카드가 없습니다.", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        // 저장된 진행 상태 복원 시도
        val savedOrderJson = prefs.getString(progressOrderKey(mode), null)
        val savedIndex = prefs.getInt(progressIndexKey(mode), -1)
        if (savedOrderJson != null && savedIndex >= 0) {
            try {
                val savedOrder = JSONArray(savedOrderJson)
                val koToCard = cards.associateBy { it.ko }
                val restoredCards = (0 until savedOrder.length()).mapNotNull { koToCard[savedOrder.getString(it)] }
                if (restoredCards.size == cards.size) {
                    cards.clear()
                    cards.addAll(restoredCards)
                    currentIndex = savedIndex.coerceIn(0, cards.size - 1)
                } else {
                    cards.shuffle()
                }
            } catch (e: Exception) {
                cards.shuffle()
            }
        } else {
            cards.shuffle()
        }

        val koText = findViewById<TextView>(R.id.koText)
        val enText = findViewById<TextView>(R.id.enText)
        val divider = findViewById<View>(R.id.divider)
        val showAnswerButton = findViewById<Button>(R.id.showAnswerButton)
        val counterText = findViewById<TextView>(R.id.counterText)
        val homeButton = findViewById<Button>(R.id.homeButton)
        val bookmarkButton = findViewById<Button>(R.id.bookmarkButton)
        val excludeButton = findViewById<Button>(R.id.excludeButton)

        fun updateBookmarkButton() {
            val isBookmarked = bookmarked.contains(cards[currentIndex].ko)
            bookmarkButton.text = if (isBookmarked) "★" else "☆"
            bookmarkButton.setTextColor(
                if (isBookmarked) ContextCompat.getColor(this, R.color.bookmarkActive)
                else ContextCompat.getColor(this, R.color.textHint)
            )
        }

        fun updateExcludeButton() {
            val isExcluded = excluded.contains(cards[currentIndex].ko)
            excludeButton.setTextColor(
                if (isExcluded) ContextCompat.getColor(this, R.color.excludeActive)
                else ContextCompat.getColor(this, R.color.textHint)
            )
        }

        fun showCard() {
            val card = cards[currentIndex]
            if (currentIndex % 2 == 0) {
                koText.text = card.ko
                enText.text = card.en
            } else {
                koText.text = card.en
                enText.text = card.ko
            }
            enText.visibility = View.INVISIBLE
            divider.visibility = View.INVISIBLE
            showAnswerButton.visibility = View.VISIBLE
            counterText.text = "${currentIndex + 1} / ${cards.size}"
            updateBookmarkButton()
            updateExcludeButton()
        }

        fun nextCard() {
            currentIndex++
            if (currentIndex >= cards.size) {
                cards.shuffle()
                currentIndex = 0
                Toast.makeText(this, "전체 완료! 카드를 다시 섞었습니다.", Toast.LENGTH_SHORT).show()
            }
            showCard()
            saveProgress()
        }

        fun prevCard() {
            currentIndex = (currentIndex - 1 + cards.size) % cards.size
            showCard()
            saveProgress()
        }

        showCard()

        showAnswerButton.setOnClickListener {
            enText.visibility = View.VISIBLE
            divider.visibility = View.VISIBLE
            showAnswerButton.visibility = View.GONE
        }

        homeButton.setOnClickListener { finish() }

        bookmarkButton.setOnClickListener {
            val cardKey = cards[currentIndex].ko
            if (bookmarked.contains(cardKey)) bookmarked.remove(cardKey)
            else bookmarked.add(cardKey)
            prefs.edit().putStringSet(KEY_BOOKMARKED, bookmarked.toSet()).apply()
            updateBookmarkButton()
        }

        excludeButton.setOnClickListener {
            val cardKey = cards[currentIndex].ko
            if (excluded.contains(cardKey)) excluded.remove(cardKey)
            else excluded.add(cardKey)
            prefs.edit().putStringSet(KEY_EXCLUDED, excluded.toSet()).apply()
            updateExcludeButton()
        }

        gestureDetector = GestureDetector(this, object : GestureDetector.SimpleOnGestureListener() {
            override fun onFling(
                e1: MotionEvent?,
                e2: MotionEvent,
                velocityX: Float,
                velocityY: Float
            ): Boolean {
                if (e1 == null) return false
                val diffX = e2.x - e1.x
                val diffY = e2.y - e1.y
                if (abs(diffX) > abs(diffY) && abs(diffX) > 80 && abs(velocityX) > 100) {
                    if (diffX < 0) nextCard() else prevCard()
                    return true
                }
                return false
            }
        })
    }

    override fun onPause() {
        super.onPause()
        saveProgress()
    }

    private fun saveProgress() {
        val orderArray = JSONArray()
        cards.forEach { orderArray.put(it.ko) }
        getSharedPreferences(PREFS, MODE_PRIVATE).edit()
            .putString(progressOrderKey(mode), orderArray.toString())
            .putInt(progressIndexKey(mode), currentIndex)
            .apply()
    }

    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        gestureDetector.onTouchEvent(ev)
        return super.dispatchTouchEvent(ev)
    }

    private fun loadCards(mode: String?) {
        val baseCards = loadBaseCards()
        val userCards = UserCardManager.load(this)

        val pool = when (mode) {
            MODE_USER -> userCards
            else -> (baseCards + userCards).toMutableList()
        }

        if (mode == MODE_BOOKMARKED) {
            cards.addAll(pool.filter { bookmarked.contains(it.ko) && !excluded.contains(it.ko) })
        } else {
            cards.addAll(pool.filter { !excluded.contains(it.ko) })
        }
    }

    private fun loadBaseCards(): List<Flashcard> {
        val raw = resources.openRawResource(R.raw.flashcards).bufferedReader().readText()
        val array = JSONArray(raw)
        return (0 until array.length()).map { i ->
            val obj = array.getJSONObject(i)
            Flashcard(ko = obj.getString("ko"), en = obj.getString("en"))
        }
    }
}
