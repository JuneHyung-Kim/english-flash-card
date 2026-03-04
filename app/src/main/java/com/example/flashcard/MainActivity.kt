package com.example.flashcard

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONArray

data class Flashcard(val ko: String, val en: String)

class MainActivity : AppCompatActivity() {

    private val cards = mutableListOf<Flashcard>()
    private var currentIndex = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        loadCards()

        val koText = findViewById<TextView>(R.id.koText)
        val enText = findViewById<TextView>(R.id.enText)
        val nextButton = findViewById<Button>(R.id.nextButton)
        val counterText = findViewById<TextView>(R.id.counterText)

        fun showCard() {
            val card = cards[currentIndex]
            koText.text = card.ko
            enText.text = card.en
            counterText.text = "${currentIndex + 1} / ${cards.size}"
        }

        showCard()

        nextButton.setOnClickListener {
            currentIndex = (currentIndex + 1) % cards.size
            showCard()
        }
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
