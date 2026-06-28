package com.paceshift

import com.paceshift.ai.GenUiService
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Unit tests for the generative-UI spec parser. These exercise the deterministic
 * core (lenient parse + allow-list filter + safe fallback) without a live GLM call.
 */
class GenUiTest {
    @Test
    fun `parses a well-formed spec`() {
        val raw = """
            {"blocks":[
              {"type":"section","title":"This week"},
              {"type":"metric","value":"3h52m","label":"Predicted finish","tone":"positive"},
              {"type":"run_card","runId":42,"title":"Long run","subtitle":"Sun · 18 km","status":"shifted"}
            ]}
        """.trimIndent()
        val spec = GenUiService.parseSpec(raw)
        assertEquals(3, spec.blocks.size)
        assertEquals("section", spec.blocks[0].type)
        assertEquals(42, spec.blocks[2].runId)
    }

    @Test
    fun `strips markdown fences`() {
        val raw = "```json\n{\"blocks\":[{\"type\":\"text\",\"body\":\"Hi\"}]}\n```"
        val spec = GenUiService.parseSpec(raw)
        assertEquals(1, spec.blocks.size)
        assertEquals("Hi", spec.blocks[0].body)
    }

    @Test
    fun `drops unknown block types`() {
        val raw = """
            {"blocks":[
              {"type":"text","body":"ok"},
              {"type":"iframe","body":"<script>"},
              {"type":"webview","value":"evil"}
            ]}
        """.trimIndent()
        val spec = GenUiService.parseSpec(raw)
        assertEquals(1, spec.blocks.size)
        assertEquals("text", spec.blocks[0].type)
    }

    @Test
    fun `caps the spec at eight blocks`() {
        val blocks = (1..20).joinToString(",") { """{"type":"text","body":"$it"}""" }
        val spec = GenUiService.parseSpec("""{"blocks":[$blocks]}""")
        assertEquals(8, spec.blocks.size)
    }

    @Test
    fun `degrades malformed output to a safe fallback`() {
        val spec = GenUiService.parseSpec("not json at all { ]")
        assertEquals(1, spec.blocks.size)
        assertEquals("text", spec.blocks[0].type)
        assertTrue(spec.blocks[0].body!!.isNotBlank())
    }

    @Test
    fun `empty block list falls back rather than rendering nothing`() {
        val spec = GenUiService.parseSpec("""{"blocks":[]}""")
        assertEquals(1, spec.blocks.size)
        assertEquals("text", spec.blocks[0].type)
    }
}
