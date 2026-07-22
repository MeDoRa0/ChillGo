import {strict as assert} from "assert";
import {Timestamp} from "firebase-admin/firestore";
import {
  ChatCommandError,
  parseChatCommand,
  trimUnicodeWhitespace,
  validateMessageText,
} from "../../src/chat/command_schema";

describe("chat command schema", () => {
  const base = {
    type: "send_message",
    outingId: "outing-1",
    crewId: "crew-1",
    requestedByUserId: "alice",
    clientMessageId: "client-message-0001",
    payload: {text: "Hello"},
    status: "pending",
    createdAt: Timestamp.now(),
  };

  it("accepts the exact pending shape and trims Unicode whitespace", () => {
    const parsed = parseChatCommand({...base, payload: {text: "\u2003Hello\u2003"}});
    assert.equal(parsed.payload.text, "Hello");
  });

  it("rejects unknown keys and invalid lifecycle state", () => {
    assert.throws(() => parseChatCommand({...base, debug: true}), ChatCommandError);
    assert.throws(() => parseChatCommand({...base, status: "processing"}), ChatCommandError);
  });

  it("counts Unicode scalar values rather than UTF-16 code units", () => {
    assert.equal(Array.from(validateMessageText("😀")).length, 1);
    assert.throws(() => validateMessageText("😀".repeat(2001)), ChatCommandError);
    assert.throws(() => validateMessageText("\n\t"), ChatCommandError);
  });

  it("supports line breaks, links, and right-to-left plain text", () => {
    assert.equal(validateMessageText("مرحبا\nhttps://example.com"), "مرحبا\nhttps://example.com");
    assert.equal(trimUnicodeWhitespace("\u00a0text\u00a0"), "text");
  });
});
