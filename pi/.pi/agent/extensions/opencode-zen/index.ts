/**
 * OpenCode Zen Provider Extension
 *
 * Registers OpenCode Zen as a single provider "opencode-zen" for pi, giving
 * access to curated and benchmarked models through the OpenCode Zen gateway.
 *
 * OpenCode Zen routes different model families to different API endpoints.
 * This extension uses a custom streamSimple that rewrites each model's baseUrl
 * before delegating to pi's built-in streaming implementations, so all models
 * live under one provider name with a single API key.
 *
 * Setup:
 *   1. Sign up at https://opencode.ai and get your API key
 *   2. Set OPENCODE_ZEN_API_KEY env var, or add to ~/.pi/agent/auth.json:
 *      { "opencode-zen": { "type": "api_key", "key": "your-key" } }
 *   3. Use /model to select an opencode-zen/* model
 *
 * Usage:
 *   OPENCODE_ZEN_API_KEY=your-key-here pi
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { streamSimple as piStreamSimple } from "@mariozechner/pi-ai";
import type { Api, AssistantMessageEventStream, Context, Model, SimpleStreamOptions } from "@mariozechner/pi-ai";

const BASE = "https://opencode.ai/zen/v1";

// Map model IDs to their correct endpoint paths
const endpointMap: Record<string, string> = {
  // GPT — OpenAI Responses API
  "gpt-5.2":            `${BASE}/responses`,
  "gpt-5.2-codex":      `${BASE}/responses`,
  "gpt-5.1":            `${BASE}/responses`,
  "gpt-5.1-codex":      `${BASE}/responses`,
  "gpt-5.1-codex-max":  `${BASE}/responses`,
  "gpt-5.1-codex-mini": `${BASE}/responses`,
  "gpt-5":              `${BASE}/responses`,
  "gpt-5-codex":        `${BASE}/responses`,
  "gpt-5-nano":         `${BASE}/responses`,

  // Claude — Anthropic Messages API
  "claude-opus-4-6":   `${BASE}/messages`,
  "claude-opus-4-5":   `${BASE}/messages`,
  "claude-opus-4-1":   `${BASE}/messages`,
  "claude-sonnet-4-6": `${BASE}/messages`,
  "claude-sonnet-4-5": `${BASE}/messages`,
  "claude-sonnet-4":   `${BASE}/messages`,
  "claude-haiku-4-5":  `${BASE}/messages`,
  "claude-3-5-haiku":  `${BASE}/messages`,

  // Gemini — Google Generative AI API (per-model paths)
  "gemini-3-pro":   `${BASE}/models/gemini-3-pro`,
  "gemini-3-flash": `${BASE}/models/gemini-3-flash`,

  // OpenAI-compatible — Chat Completions API
  "minimax-m2.5":      `${BASE}/chat/completions`,
  "minimax-m2.5-free": `${BASE}/chat/completions`,
  "minimax-m2.1":      `${BASE}/chat/completions`,
  "glm-5":             `${BASE}/chat/completions`,
  "glm-5-free":        `${BASE}/chat/completions`,
  "glm-4.7":           `${BASE}/chat/completions`,
  "glm-4.6":           `${BASE}/chat/completions`,
  "kimi-k2.5":         `${BASE}/chat/completions`,
  "kimi-k2.5-free":    `${BASE}/chat/completions`,
  "kimi-k2-thinking":  `${BASE}/chat/completions`,
  "kimi-k2":           `${BASE}/chat/completions`,
  "qwen3-coder":       `${BASE}/chat/completions`,
  "big-pickle":        `${BASE}/chat/completions`,
};

function zenStream(
  model: Model<Api>,
  context: Context,
  options?: SimpleStreamOptions,
): AssistantMessageEventStream {
  const targetUrl = endpointMap[model.id];
  if (!targetUrl) {
    throw new Error(`OpenCode Zen: unknown model "${model.id}"`);
  }

  // Rewrite the model's baseUrl to the correct endpoint, then delegate
  const rewritten = { ...model, baseUrl: targetUrl };
  return piStreamSimple(rewritten, context, options);
}

export default function (pi: ExtensionAPI) {
  pi.registerProvider("opencode-zen", {
    baseUrl: BASE,
    apiKey: "OPENCODE_ZEN_API_KEY",
    // Use a custom API identifier so we can provide our own streamSimple
    api: "opencode-zen",
    authHeader: true,
    streamSimple: zenStream,

    models: [
      // =======================================================================
      // GPT models — OpenAI Responses API
      // =======================================================================
      {
        id: "gpt-5.2",
        name: "GPT 5.2",
        api: "openai-responses",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 1.75, output: 14.0, cacheRead: 0.175, cacheWrite: 0 },
        contextWindow: 200000,
        maxTokens: 32768,
      },
      {
        id: "gpt-5.2-codex",
        name: "GPT 5.2 Codex",
        api: "openai-codex-responses",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 1.75, output: 14.0, cacheRead: 0.175, cacheWrite: 0 },
        contextWindow: 200000,
        maxTokens: 32768,
      },
      {
        id: "gpt-5.1",
        name: "GPT 5.1",
        api: "openai-responses",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 1.07, output: 8.5, cacheRead: 0.107, cacheWrite: 0 },
        contextWindow: 200000,
        maxTokens: 32768,
      },
      {
        id: "gpt-5.1-codex",
        name: "GPT 5.1 Codex",
        api: "openai-codex-responses",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 1.07, output: 8.5, cacheRead: 0.107, cacheWrite: 0 },
        contextWindow: 200000,
        maxTokens: 32768,
      },
      {
        id: "gpt-5.1-codex-max",
        name: "GPT 5.1 Codex Max",
        api: "openai-codex-responses",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 1.25, output: 10.0, cacheRead: 0.125, cacheWrite: 0 },
        contextWindow: 200000,
        maxTokens: 65536,
      },
      {
        id: "gpt-5.1-codex-mini",
        name: "GPT 5.1 Codex Mini",
        api: "openai-codex-responses",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 0.25, output: 2.0, cacheRead: 0.025, cacheWrite: 0 },
        contextWindow: 200000,
        maxTokens: 16384,
      },
      {
        id: "gpt-5",
        name: "GPT 5",
        api: "openai-responses",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 1.07, output: 8.5, cacheRead: 0.107, cacheWrite: 0 },
        contextWindow: 200000,
        maxTokens: 32768,
      },
      {
        id: "gpt-5-codex",
        name: "GPT 5 Codex",
        api: "openai-codex-responses",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 1.07, output: 8.5, cacheRead: 0.107, cacheWrite: 0 },
        contextWindow: 200000,
        maxTokens: 32768,
      },
      {
        id: "gpt-5-nano",
        name: "GPT 5 Nano (Free)",
        api: "openai-responses",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
      },

      // =======================================================================
      // Claude models — Anthropic Messages API
      // =======================================================================
      {
        id: "claude-opus-4-6",
        name: "Claude Opus 4.6",
        api: "anthropic-messages",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 5.0, output: 25.0, cacheRead: 0.5, cacheWrite: 6.25 },
        contextWindow: 200000,
        maxTokens: 64000,
      },
      {
        id: "claude-opus-4-5",
        name: "Claude Opus 4.5",
        api: "anthropic-messages",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 5.0, output: 25.0, cacheRead: 0.5, cacheWrite: 6.25 },
        contextWindow: 200000,
        maxTokens: 64000,
      },
      {
        id: "claude-opus-4-1",
        name: "Claude Opus 4.1",
        api: "anthropic-messages",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 15.0, output: 75.0, cacheRead: 1.5, cacheWrite: 18.75 },
        contextWindow: 200000,
        maxTokens: 64000,
      },
      {
        id: "claude-sonnet-4-6",
        name: "Claude Sonnet 4.6",
        api: "anthropic-messages",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 3.0, output: 15.0, cacheRead: 0.3, cacheWrite: 3.75 },
        contextWindow: 200000,
        maxTokens: 64000,
      },
      {
        id: "claude-sonnet-4-5",
        name: "Claude Sonnet 4.5",
        api: "anthropic-messages",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 3.0, output: 15.0, cacheRead: 0.3, cacheWrite: 3.75 },
        contextWindow: 200000,
        maxTokens: 64000,
      },
      {
        id: "claude-sonnet-4",
        name: "Claude Sonnet 4",
        api: "anthropic-messages",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 3.0, output: 15.0, cacheRead: 0.3, cacheWrite: 3.75 },
        contextWindow: 200000,
        maxTokens: 64000,
      },
      {
        id: "claude-haiku-4-5",
        name: "Claude Haiku 4.5",
        api: "anthropic-messages",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 1.0, output: 5.0, cacheRead: 0.1, cacheWrite: 1.25 },
        contextWindow: 200000,
        maxTokens: 64000,
      },
      {
        id: "claude-3-5-haiku",
        name: "Claude Haiku 3.5",
        api: "anthropic-messages",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 0.8, output: 4.0, cacheRead: 0.08, cacheWrite: 1.0 },
        contextWindow: 200000,
        maxTokens: 8192,
      },

      // =======================================================================
      // Gemini models — Google Generative AI API
      // =======================================================================
      {
        id: "gemini-3-pro",
        name: "Gemini 3 Pro",
        api: "google-generative-ai",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 2.0, output: 12.0, cacheRead: 0.2, cacheWrite: 0 },
        contextWindow: 1000000,
        maxTokens: 65536,
      },
      {
        id: "gemini-3-flash",
        name: "Gemini 3 Flash",
        api: "google-generative-ai",
        reasoning: true,
        input: ["text", "image"],
        cost: { input: 0.5, output: 3.0, cacheRead: 0.05, cacheWrite: 0 },
        contextWindow: 1000000,
        maxTokens: 65536,
      },

      // =======================================================================
      // OpenAI-compatible models — Chat Completions API
      // =======================================================================

      // MiniMax
      {
        id: "minimax-m2.5",
        name: "MiniMax M2.5",
        api: "openai-completions",
        reasoning: false,
        input: ["text"],
        cost: { input: 0.3, output: 1.2, cacheRead: 0.06, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
        compat: { supportsDeveloperRole: false, maxTokensField: "max_tokens" },
      },
      {
        id: "minimax-m2.5-free",
        name: "MiniMax M2.5 (Free)",
        api: "openai-completions",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
        compat: { supportsDeveloperRole: false, maxTokensField: "max_tokens" },
      },
      {
        id: "minimax-m2.1",
        name: "MiniMax M2.1",
        api: "openai-completions",
        reasoning: false,
        input: ["text"],
        cost: { input: 0.3, output: 1.2, cacheRead: 0.1, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
        compat: { supportsDeveloperRole: false, maxTokensField: "max_tokens" },
      },

      // GLM
      {
        id: "glm-5",
        name: "GLM 5",
        api: "openai-completions",
        reasoning: false,
        input: ["text"],
        cost: { input: 1.0, output: 3.2, cacheRead: 0.2, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
        compat: { supportsDeveloperRole: false, maxTokensField: "max_tokens" },
      },
      {
        id: "glm-5-free",
        name: "GLM 5 (Free)",
        api: "openai-completions",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
        compat: { supportsDeveloperRole: false, maxTokensField: "max_tokens" },
      },
      {
        id: "glm-4.7",
        name: "GLM 4.7",
        api: "openai-completions",
        reasoning: false,
        input: ["text"],
        cost: { input: 0.6, output: 2.2, cacheRead: 0.1, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
        compat: { supportsDeveloperRole: false, maxTokensField: "max_tokens" },
      },
      {
        id: "glm-4.6",
        name: "GLM 4.6",
        api: "openai-completions",
        reasoning: false,
        input: ["text"],
        cost: { input: 0.6, output: 2.2, cacheRead: 0.1, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
        compat: { supportsDeveloperRole: false, maxTokensField: "max_tokens" },
      },

      // Kimi
      {
        id: "kimi-k2.5",
        name: "Kimi K2.5",
        api: "openai-completions",
        reasoning: false,
        input: ["text"],
        cost: { input: 0.6, output: 3.0, cacheRead: 0.08, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
        compat: { supportsDeveloperRole: false, maxTokensField: "max_tokens" },
      },
      {
        id: "kimi-k2.5-free",
        name: "Kimi K2.5 (Free)",
        api: "openai-completions",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
        compat: { supportsDeveloperRole: false, maxTokensField: "max_tokens" },
      },
      {
        id: "kimi-k2-thinking",
        name: "Kimi K2 Thinking",
        api: "openai-completions",
        reasoning: true,
        input: ["text"],
        cost: { input: 0.4, output: 2.5, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
        compat: { supportsDeveloperRole: false, maxTokensField: "max_tokens" },
      },
      {
        id: "kimi-k2",
        name: "Kimi K2",
        api: "openai-completions",
        reasoning: false,
        input: ["text"],
        cost: { input: 0.4, output: 2.5, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
        compat: { supportsDeveloperRole: false, maxTokensField: "max_tokens" },
      },

      // Qwen
      {
        id: "qwen3-coder",
        name: "Qwen3 Coder 480B",
        api: "openai-completions",
        reasoning: true,
        input: ["text"],
        cost: { input: 0.45, output: 1.5, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
        compat: { supportsDeveloperRole: false, maxTokensField: "max_tokens", thinkingFormat: "qwen" },
      },

      // Big Pickle
      {
        id: "big-pickle",
        name: "Big Pickle (Free)",
        api: "openai-completions",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384,
        compat: { supportsDeveloperRole: false, maxTokensField: "max_tokens" },
      },
    ],
  });
}
