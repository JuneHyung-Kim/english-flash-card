package com.example.flashcard

import android.os.Bundle
import android.view.MotionEvent
import android.view.GestureDetector
import android.view.View
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONArray
import kotlin.math.abs

data class Flashcard(val ko: String, val en: String)

class FlashcardActivity : AppCompatActivity() {

    private val cards = mutableListOf<Flashcard>()
    private var currentIndex = 0
    private lateinit var gestureDetector: GestureDetector

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_flashcard)

        loadCards()
        cards.shuffle()

        val koText = findViewById<TextView>(R.id.koText)
        val enText = findViewById<TextView>(R.id.enText)
        val divider = findViewById<View>(R.id.divider)
        val showAnswerButton = findViewById<Button>(R.id.showAnswerButton)
        val counterText = findViewById<TextView>(R.id.counterText)
        val homeButton = findViewById<Button>(R.id.homeButton)

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

        homeButton.setOnClickListener {
            finish()
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
