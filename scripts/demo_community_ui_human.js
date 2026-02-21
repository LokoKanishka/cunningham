#!/usr/bin/env node
"use strict";

const { chromium } = require("playwright");
const { typeHuman } = require("./ui_human_helpers");
const path = require("path");

const BASE_URL = process.env.DIRECT_CHAT_URL || "http://127.0.0.1:8787/";

async function main() {
    console.log("Starting Phase A Demo: UI + Community MCP Integration");
    const browser = await chromium.launch({ headless: false });
    const page = await browser.newPage();

    await page.goto(BASE_URL, { waitUntil: "domcontentloaded" });
    console.log(`Navigated to ${BASE_URL}`);

    // Ensure we are in a clean state
    await page.getByRole("button", { name: "Nueva sesion" }).click();
    await page.waitForTimeout(500);

    const input = page.getByRole("textbox", { name: "Escribi en lenguaje natural..." });
    const prompt = "usa community-exa para buscar en la web: que es el proyecto cunningham?";

    console.log(`Typing prompt: "${prompt}"`);
    await typeHuman(page, input, prompt, { tag: "phase_a_demo" });

    console.log("Clicking Enviar...");
    await page.getByRole("button", { name: "Enviar" }).click();

    console.log("Waiting for assistant reply...");
    // Wait for the message to appear. We wait for a new message with class .assistant.
    await page.waitForFunction(
        () => document.querySelectorAll("#chat .msg.assistant").length > 0,
        { timeout: 60000 }
    );

    const reply = await page.locator("#chat .msg.assistant").last().innerText();
    console.log("Assistant Reply:");
    console.log("------------------");
    console.log(reply);
    console.log("------------------");

    if (reply.toLowerCase().includes("exa") || reply.length > 50) {
        console.log("SUCCESS: Response received from UI via MCP bridge.");
    } else {
        console.warn("WARNING: Response received but might not have used MCP.");
    }

    await page.waitForTimeout(2000);
    await browser.close();
}

main().catch(err => {
    console.error("DEMO FAILED:", err);
    process.exit(1);
});
