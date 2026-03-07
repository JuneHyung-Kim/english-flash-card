package com.example.flashcard

import android.content.Intent
import android.os.Bundle
import android.view.View
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

        findViewById<Button>(R.id.bookmarkedButton).setOnClickListener {
            startActivity(Intent(this, FlashcardActivity::class.java).apply {
                putExtra(FlashcardActivity.EXTRA_MODE, FlashcardActivity.MODE_BOOKMARKED)
            })
        }
    }

    override fun onResume() {
        super.onResume()
        val count = getBookmarkedCount()
        val btn = findViewById<Button>(R.id.bookmarkedButton)
        if (count > 0) {
            btn.visibility = View.VISIBLE
            btn.text = "저장한 카드 학습 (${count}장)"
        } else {
            btn.visibility = View.GONE
        }
    }

    private fun loadCardCount(): Int {
        val raw = resources.openRawResource(R.raw.flashcards).bufferedReader().readText()
        return JSONArray(raw).length()
    }

    private fun getBookmarkedCount(): Int {
        val prefs = getSharedPreferences("flashcard_prefs", MODE_PRIVATE)
        return (prefs.getStringSet("bookmarked", emptySet()) ?: emptySet()).size
    }
}
