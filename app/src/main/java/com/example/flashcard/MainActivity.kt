package com.example.flashcard

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONArray

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val cardCount = loadCardCount()
        findViewById<TextView>(R.id.cardCountText).text = "총 ${cardCount}장의 카드"

        findViewById<Button>(R.id.startButton).setOnClickListener {
            startActivity(Intent(this, FlashcardActivity::class.java))
        }
    }

    private fun loadCardCount(): Int {
        val raw = resources.openRawResource(R.raw.flashcards).bufferedReader().readText()
        return JSONArray(raw).length()
    }
}
