package com.example.flashcard

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONArray

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        findViewById<Button>(R.id.startButton).setOnClickListener {
            startActivity(Intent(this, FlashcardActivity::class.java))
        }
        findViewById<Button>(R.id.bookmarkedButton).setOnClickListener {
            startActivity(Intent(this, FlashcardActivity::class.java).apply {
                putExtra(FlashcardActivity.EXTRA_MODE, FlashcardActivity.MODE_BOOKMARKED)
            })
        }
        findViewById<Button>(R.id.userCardsButton).setOnClickListener {
            startActivity(Intent(this, FlashcardActivity::class.java).apply {
                putExtra(FlashcardActivity.EXTRA_MODE, FlashcardActivity.MODE_USER)
            })
        }
        findViewById<Button>(R.id.addCardButton).setOnClickListener {
            startActivity(Intent(this, AddCardActivity::class.java))
        }
    }

    override fun onResume() {
        super.onResume()

        val userCards = UserCardManager.load(this)
        val baseCount = JSONArray(resources.openRawResource(R.raw.flashcards).bufferedReader().readText()).length()
        val totalCount = baseCount + userCards.size
        findViewById<TextView>(R.id.cardCountText).text = "총 ${totalCount}장의 카드"

        val prefs = getSharedPreferences("flashcard_prefs", MODE_PRIVATE)

        val bookmarkCount = (prefs.getStringSet("bookmarked", emptySet()) ?: emptySet()).size
        findViewById<Button>(R.id.bookmarkedButton).apply {
            visibility = if (bookmarkCount > 0) View.VISIBLE else View.GONE
            text = "저장한 카드 학습 (${bookmarkCount}장)"
        }

        findViewById<Button>(R.id.userCardsButton).apply {
            visibility = if (userCards.isNotEmpty()) View.VISIBLE else View.GONE
            text = "내가 추가한 카드 (${userCards.size}장)"
        }

        val excludedCount = (prefs.getStringSet(FlashcardActivity.KEY_EXCLUDED, emptySet()) ?: emptySet()).size
        findViewById<Button>(R.id.excludedManageButton).apply {
            visibility = if (excludedCount > 0) View.VISIBLE else View.GONE
            text = "제외된 카드 ${excludedCount}장 복원"
            setOnClickListener {
                AlertDialog.Builder(this@MainActivity)
                    .setTitle("제외된 카드 복원")
                    .setMessage("제외된 카드 ${excludedCount}장을 모두 복원하시겠습니까?")
                    .setPositiveButton("복원") { _, _ ->
                        prefs.edit().remove(FlashcardActivity.KEY_EXCLUDED).apply()
                        onResume()
                    }
                    .setNegativeButton("취소", null)
                    .show()
            }
        }
    }
}
