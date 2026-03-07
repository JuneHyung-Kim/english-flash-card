package com.example.flashcard

import android.graphics.Color
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

    companion object {
        const val EXTRA_MODE = "mode"
        const val MODE_BOOKMARKED = "bookmarked"
        private const val PREFS = "flashcard_prefs"
        private const val KEY_BOOKMARKED = "bookmarked"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_flashcard)

        val prefs = getSharedPreferences(PREFS, MODE_PRIVATE)
        bookmarked = (prefs.getStringSet(KEY_BOOKMARKED, emptySet()) ?: emptySet()).toMutableSet()

        loadCards()

        val isBookmarkedMode = intent.getStringExtra(EXTRA_MODE) == MODE_BOOKMARKED
        if (isBookmarkedMode) {
            val filtered = cards.filter { bookmarked.contains(it.ko) }
            if (filtered.isEmpty()) {
                Toast.makeText(this, "저장한 카드가 없습니다.", Toast.LENGTH_SHORT).show()
                finish()
                return
            }
            cards.clear()
            cards.addAll(filtered)
        }

        cards.shuffle()

        val koText = findViewById<TextView>(R.id.koText)
        val enText = findViewById<TextView>(R.id.enText)
        val divider = findViewById<View>(R.id.divider)
        val showAnswerButton = findViewById<Button>(R.id.showAnswerButton)
        val counterText = findViewById<TextView>(R.id.counterText)
        val homeButton = findViewById<Button>(R.id.homeButton)
        val bookmarkButton = findViewById<Button>(R.id.bookmarkButton)

        fun updateBookmarkButton() {
            val isBookmarked = bookmarked.contains(cards[currentIndex].ko)
            bookmarkButton.text = if (isBookmarked) "★" else "☆"
            bookmarkButton.setTextColor(
                if (isBookmarked) Color.parseColor("#FFC107")
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
        }

        fun nextCard() {
            currentIndex++
            if (currentIndex >= cards.size) {
                cards.shuffle()
                currentIndex = 0
                Toast.makeText(this, "전체 완료! 카드를 다시 섞었습니다.", Toast.LENGTH_SHORT).show()
            }
            showCard()
        }

        fun prevCard() {
            currentIndex = (currentIndex - 1 + cards.size) % cards.size
            showCard()
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

    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        gestureDetector.onTouchEvent(ev)
        return super.dispatchTouchEvent(ev)
    }

    private fun loadCards() {
        val raw = resources.openRawResource(R.raw.flashcards).bufferedReader().readText()
        val array = JSONArray(raw)
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            cards.add(Flashcard(ko = obj.getString("ko"), en = obj.getString("en")))
        }
    }
}
