package com.example.flashcard

import android.os.Bundle
import android.view.Gravity
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat

class AddCardActivity : AppCompatActivity() {

    private val userCards = mutableListOf<Flashcard>()
    private lateinit var cardListLayout: LinearLayout
    private lateinit var listHeader: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_add_card)

        userCards.addAll(UserCardManager.load(this))

        val koInput = findViewById<EditText>(R.id.koInput)
        val enInput = findViewById<EditText>(R.id.enInput)
        val saveButton = findViewById<Button>(R.id.saveButton)
        cardListLayout = findViewById(R.id.cardListLayout)
        listHeader = findViewById(R.id.listHeader)

        renderCardList()

        findViewById<Button>(R.id.backButton).setOnClickListener { finish() }

        saveButton.setOnClickListener {
            val ko = koInput.text.toString().trim()
            val en = enInput.text.toString().trim()
            if (ko.isEmpty() || en.isEmpty()) {
                Toast.makeText(this, "한국어와 영어를 모두 입력해주세요.", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            userCards.add(Flashcard(ko, en))
            UserCardManager.save(this, userCards)
            koInput.text.clear()
            enInput.text.clear()
            renderCardList()
        }
    }

    private fun renderCardList() {
        cardListLayout.removeAllViews()
        listHeader.text = if (userCards.isEmpty()) "추가한 카드가 없습니다." else "추가한 카드 (${userCards.size}장)"

        userCards.forEachIndexed { index, card ->
            val row = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(0, 20, 0, 20)
            }

            val text = TextView(this).apply {
                text = "${card.ko}  /  ${card.en}"
                textSize = 14f
                setTextColor(ContextCompat.getColor(context, R.color.textPrimary))
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }

            val deleteButton = Button(this).apply {
                this.text = "삭제"
                textSize = 12f
                setTextColor(ContextCompat.getColor(context, R.color.textHint))
                style(this)
                setOnClickListener {
                    userCards.removeAt(index)
                    UserCardManager.save(this@AddCardActivity, userCards)
                    renderCardList()
                }
            }

            row.addView(text)
            row.addView(deleteButton)
            cardListLayout.addView(row)

            val divider = android.view.View(this).apply {
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 1)
                setBackgroundColor(ContextCompat.getColor(context, R.color.divider))
            }
            cardListLayout.addView(divider)
        }
    }

    private fun style(button: Button) {
        button.isAllCaps = false
        button.background = null
    }
}
