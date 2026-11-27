// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.testbed

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.util.Log
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONObject

/**
 * DEBUG BUILDS ONLY. One EditText per input type so automated tests can type
 * into each and read the result back from logcat:
 *
 *   adb shell am start -n app.booboard.keyboard/.testbed.TestbedActivity --es focus email --ez clear true
 *   adb logcat -d -s BooBoardTestbed
 *
 * Each change logs `<field>=<json-quoted text>`; editor actions log `<field>!action=<id>`.
 */
class TestbedActivity : Activity() {

    private val fields = linkedMapOf<String, EditText>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 32, 32, 32)
        }
        for ((name, spec) in SPECS) {
            column.addView(TextView(this).apply { text = name })
            val edit = EditText(this).apply {
                inputType = spec.first
                imeOptions = spec.second
                tag = name
                if (spec.first == InputType.TYPE_NULL) isFocusableInTouchMode = true
                addTextChangedListener(object : TextWatcher {
                    override fun beforeTextChanged(s: CharSequence?, a: Int, b: Int, c: Int) {}
                    override fun onTextChanged(s: CharSequence?, a: Int, b: Int, c: Int) {}
                    override fun afterTextChanged(s: Editable?) {
                        Log.i(TAG, "$name=${JSONObject.quote(s?.toString() ?: "")}")
                    }
                })
                setOnEditorActionListener { _, actionId, _ ->
                    Log.i(TAG, "$name!action=$actionId")
                    false
                }
            }
            fields[name] = edit
            column.addView(edit, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        }
        setContentView(ScrollView(this).apply { addView(column) })
        handle(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handle(intent)
    }

    private fun handle(intent: Intent?) {
        if (intent?.getBooleanExtra("clear", false) == true) fields.values.forEach { it.setText("") }
        val focus = intent?.getStringExtra("focus") ?: return
        val edit = fields[focus] ?: return
        edit.requestFocus()
        edit.post {
            (getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager)
                .showSoftInput(edit, InputMethodManager.SHOW_IMPLICIT)
        }
    }

    private companion object {
        const val TAG = "BooBoardTestbed"
        val TEXT = InputType.TYPE_CLASS_TEXT
        val SPECS: Map<String, Pair<Int, Int>> = linkedMapOf(
            "text" to Pair(TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES or InputType.TYPE_TEXT_FLAG_AUTO_CORRECT, EditorInfo.IME_ACTION_DONE),
            "multiline" to Pair(TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES, EditorInfo.IME_ACTION_NONE),
            "search" to Pair(TEXT, EditorInfo.IME_ACTION_SEARCH),
            "send" to Pair(TEXT or InputType.TYPE_TEXT_VARIATION_SHORT_MESSAGE or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES, EditorInfo.IME_ACTION_SEND),
            "password" to Pair(TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD, EditorInfo.IME_ACTION_DONE),
            "visible_password" to Pair(TEXT or InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD, EditorInfo.IME_ACTION_DONE),
            "email" to Pair(TEXT or InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS, EditorInfo.IME_ACTION_NEXT),
            "url" to Pair(TEXT or InputType.TYPE_TEXT_VARIATION_URI, EditorInfo.IME_ACTION_GO),
            "name" to Pair(TEXT or InputType.TYPE_TEXT_VARIATION_PERSON_NAME or InputType.TYPE_TEXT_FLAG_CAP_WORDS, EditorInfo.IME_ACTION_NEXT),
            "no_suggestions" to Pair(TEXT or InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS, EditorInfo.IME_ACTION_DONE),
            "incognito" to Pair(TEXT, EditorInfo.IME_ACTION_DONE or EditorInfo.IME_FLAG_NO_PERSONALIZED_LEARNING),
            "number" to Pair(InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_DECIMAL, EditorInfo.IME_ACTION_DONE),
            "number_password" to Pair(InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_VARIATION_PASSWORD, EditorInfo.IME_ACTION_DONE),
            "phone" to Pair(InputType.TYPE_CLASS_PHONE, EditorInfo.IME_ACTION_DONE),
            "date" to Pair(InputType.TYPE_CLASS_DATETIME or InputType.TYPE_DATETIME_VARIATION_DATE, EditorInfo.IME_ACTION_DONE),
            "raw" to Pair(InputType.TYPE_NULL, EditorInfo.IME_ACTION_NONE),
        )
    }
}
