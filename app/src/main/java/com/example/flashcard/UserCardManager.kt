package com.example.flashcard

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

object UserCardManager {
    private const val FILE_NAME = "user_cards.json"

    fun load(context: Context): MutableList<Flashcard> {
        val file = File(context.filesDir, FILE_NAME)
        if (!file.exists()) return mutableListOf()
        val array = JSONArray(file.readText())
        val list = mutableListOf<Flashcard>()
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            list.add(Flashcard(ko = obj.getString("ko"), en = obj.getString("en")))
        }
        return list
    }

    fun save(context: Context, cards: List<Flashcard>) {
        val array = JSONArray()
        cards.forEach { card ->
            array.put(JSONObject().apply {
                put("ko", card.ko)
                put("en", card.en)
            })
        }
        File(context.filesDir, FILE_NAME).writeText(array.toString())
    }
}
