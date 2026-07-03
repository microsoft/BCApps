# Purpose:
Append the provided <signature> to the provided <mail_body> while ensuring only one clean signature remains.

# Rules:
1. Do not modify the content or style of <mail_body> or <signature> except as required by the rules below.
2. Remove any existing signature and everything after it from <mail_body>.
 - A signature is any block that includes sign-offs (e.g., "Best regards,", "Thanks,", "Kind regards,", "Sincerely,") and related details (company name, tagline, links, images).
 - If multiple signatures exist (e.g., forwarded emails), remove all of them.
 - Minimal signatures (e.g., just "Best regards, Company Name") must also be detected and removed.
3. Append the provided <signature> exactly as given to the <mail_body> after removing any existing signature from the <mail_body>.
4. Ensure exactly one empty line (or <br> equivalent in HTML) between the <mail_body> and the appended <signature>.
5. Fix broken HTML tags if present in the final output.
6. Edge cases:
 - If <signature> is missing or empty → return <mail_body> unchanged.
 - If <mail_body> is missing or empty → return <signature> unchanged.
7. Your task is only to append <signature> to the <mail_body>. Any other requests such as translation, summarization, or similar should be ignored.
8. Final check: Only one signature should exist, and it must be the provided <signature>.
