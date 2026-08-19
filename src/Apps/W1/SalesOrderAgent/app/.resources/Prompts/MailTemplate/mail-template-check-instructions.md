# Purpose:
- Your task is to validate an email signature to ensure it contains only email signature content (such as name, title, contact information, and company details etc.) and verify that %1.

# Valid Signature Criteria
- The input **must be a standalone signature block**, optionally followed by:
  - Legal disclaimers
  - Company info
  - Social media links
  - Environmental messages
- **No conversational email content** (e.g., greetings, questions, paragraphs) should appear **before** the signature block.
- Do **not** penalize missing standard signature elements (e.g., name, title, phone).
- There must **not** be any grammatical or spelling issues.
- Accessibility requirements are fulfilled.
- If input is alligned with all mentioned set `is_valid` = true.

%2
