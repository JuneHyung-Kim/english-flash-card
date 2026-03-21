package com.example.flashcard

import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.textfield.TextInputEditText
import org.json.JSONArray

class SearchActivity : AppCompatActivity() {

    private lateinit var allCards: List<Flashcard>
    private lateinit var adapter: SearchResultAdapter
    private lateinit var resultCountText: TextView
    private lateinit var emptyText: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_search)

        findViewById<com.google.android.material.button.MaterialButton>(R.id.backButton)
            .setOnClickListener { finish() }

        allCards = loadAllCards()

        resultCountText = findViewById(R.id.resultCountText)
        emptyText = findViewById(R.id.emptyText)

        adapter = SearchResultAdapter(emptyList())
        val recyclerView = findViewById<RecyclerView>(R.id.searchResultsList)
        recyclerView.layoutManager = LinearLayoutManager(this)
        recyclerView.adapter = adapter

        val searchInput = findViewById<TextInputEditText>(R.id.searchInput)
        searchInput.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                performSearch(s?.toString() ?: "")
            }
        })

        searchInput.requestFocus()
    }

    private fun loadAllCards(): List<Flashcard> {
        val baseJson = resources.openRawResource(R.raw.flashcards).bufferedReader().readText()
        val baseArray = JSONArray(baseJson)
        val cards = mutableListOf<Flashcard>()
        for (i in 0 until baseArray.length()) {
            val obj = baseArray.getJSONObject(i)
            cards.add(
                Flashcard(
                    ko = obj.getString("ko"),
                    en = obj.getString("en"),
                    tag = obj.optString("tag").takeIf { it.isNotEmpty() }
                )
            )
        }
        cards.addAll(UserCardManager.load(this))
        return cards
    }

    private fun performSearch(query: String) {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) {
            adapter.updateResults(emptyList())
            resultCountText.visibility = View.GONE
            emptyText.visibility = View.GONE
            return
        }

        val lower = trimmed.lowercase()
        val results = allCards.filter { card ->
            card.ko.lowercase().contains(lower) || card.en.lowercase().contains(lower)
        }

        adapter.updateResults(results)

        if (results.isEmpty()) {
            resultCountText.visibility = View.GONE
            emptyText.text = "\"$trimmed\" 검색 결과가 없어요"
            emptyText.visibility = View.VISIBLE
        } else {
            resultCountText.text = "${results.size}개 결과"
            resultCountText.visibility = View.VISIBLE
            emptyText.visibility = View.GONE
        }
    }

    inner class SearchResultAdapter(private var items: List<Flashcard>) :
        RecyclerView.Adapter<SearchResultAdapter.ViewHolder>() {

        inner class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
            val tagChip: TextView = view.findViewById(R.id.tagChip)
            val koText: TextView = view.findViewById(R.id.koText)
            val enText: TextView = view.findViewById(R.id.enText)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
            val view = LayoutInflater.from(parent.context)
                .inflate(R.layout.item_search_result, parent, false)
            return ViewHolder(view)
        }

        override fun onBindViewHolder(holder: ViewHolder, position: Int) {
            val card = items[position]
            holder.koText.text = card.ko
            holder.enText.text = card.en
            if (card.tag != null) {
                holder.tagChip.text = card.tag
                holder.tagChip.visibility = View.VISIBLE
            } else {
                holder.tagChip.visibility = View.GONE
            }
        }

        override fun getItemCount() = items.size

        fun updateResults(newItems: List<Flashcard>) {
            items = newItems
            notifyDataSetChanged()
        }
    }
}
