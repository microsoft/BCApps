Manual Test: Shopify Tax Agent UI Walkthrough

  Scenario: A Shopify order #1005 has been imported. It ships to New York, US. It has three tax lines:
  - "NEW YORK STATE TAX" at 4.00%
  - "NEW YORK CITY CITY T" at 4.50%
  - "METROPOLITAN COMMUTE" at 0.38%

  Assume the shop code is TEST. An agent has been created for this shop with auto-create enabled
  for both jurisdictions and tax areas, and naming pattern SHPFY-AUTO-.

  ---
  Prerequisites

  1. Have a Shopify shop configured with code TEST
  2. Create a Shopify Tax Matching Agent on the Agents page, configured for shop TEST with:
    - Auto Create Tax Jurisdictions = Yes
    - Auto Create Tax Areas = Yes
    - Tax Area Naming Pattern = SHPFY-AUTO-
  3. Import (or manually create) a Shopify order with tax lines as described above
  4. Set the order's On Hold = Yes (the agent event subscriber does this automatically when an enabled agent exists for the shop)
  5. The agent uses the "Shpfy Tax Agent" profile with a dedicated role center. All navigation is from the role center or from actions on the current page — the agent cannot use the search bar.

  ---
  Step 1: Review task message settings

  The agent receives its configuration in the task message. For this manual walkthrough, note:
  1. The task message would contain:
    - Shopify Order No.: 1005
    - Ship-to Country: US, County: NY
    - Shop Code: TEST
    - Auto Create Tax Jurisdictions: Yes
    - Auto Create Tax Areas: Yes
    - Tax Area Naming Pattern: SHPFY-AUTO-
  2. These settings were configured on the agent setup page (not the Shop Card)

  ---
  Step 2: Open the order and review tax lines

  3. From the role center, click "Shopify Orders"
  4. Filter by Shop Code = TEST and Shopify Order No. = 1005, then open it
  5. Verify On Hold = Yes
  6. Note the shipping address:
    - Ship-to Country/Region Code: US
    - Ship-to County: NY (visible in the Ship-to group)
    - Ship-to City: New York
    - Ship-to Post Code: 10036
  7. Click the **Tax Lines** action on the order page. This opens the Shopify Order Tax Lines page showing all tax lines across all order lines.
  8. For each tax line, note:
    - Tax line 1: Title = NEW YORK STATE TAX, Rate % = 4.00, Tax Group Code = TAXABLE, Channel Liable = No
    - Tax line 2: Title = NEW YORK CITY CITY T, Rate % = 4.50, Tax Group Code = TAXABLE, Channel Liable = No
    - Tax line 3: Title = METROPOLITAN COMMUTE, Rate % = 0.38, Tax Group Code = TAXABLE, Channel Liable = No

  ---
  Step 3: Match each tax line to a Tax Jurisdiction

  Repeat the following process for EACH tax line. The flow for one tax line is:
  find/create jurisdiction → verify/create Tax Detail → assign jurisdiction code on the tax line.

  --- Tax Line 1: "NEW YORK STATE TAX" (4.00%) ---

  9. From the Tax Lines page, click the "Tax Jurisdictions" action (or from the role center)
  10. Search for NEW YORK STATE TAX — check if any jurisdiction's Description or Code matches
  11. If no exact match, try searching for: NY, then NEW YORK, then STATE
  12. If a candidate jurisdiction is found (e.g., Code = "NY"):
    a. Select it and click the "Details" action to open Tax Details
    b. Look for a Tax Detail where:
       - Tax Group Code = TAXABLE (the Tax Group Code from step 8)
       - Tax Below Maximum = 4.00 (the Rate % from the tax line)
       - Effective Date is on or before the order date
    c. If found: the jurisdiction is confirmed. Note the Code (e.g., "NY"). Skip to step 15.
    d. If no matching Tax Detail: create one in the Tax Details list:
       - Tax Group Code = TAXABLE
       - Tax Type = Sales Tax
       - Effective Date = (order's Document Date)
       - Tax Below Maximum = 4.00
       Then the jurisdiction is confirmed. Note the Code. Skip to step 15.
  13. If no candidate jurisdiction found (and auto-create is enabled):
    a. Add a new row in the Tax Jurisdictions list:
       - Code: NYSTAX
       - Description: New York State Tax
    b. Click the "Details" action on the new jurisdiction
    c. Add a new Tax Detail:
       - Tax Group Code = TAXABLE
       - Tax Type = Sales Tax
       - Effective Date = (order's Document Date)
       - Tax Below Maximum = 4.00
  14. Note the jurisdiction code: NYSTAX (or whatever was found/created)
  15. Go back to the Tax Lines page for order #1005
  16. Find the NEW YORK STATE TAX row and set Tax Jurisdiction Code = NYSTAX (or the code from step 12)

  --- Tax Line 2: "NEW YORK CITY CITY T" (4.50%) ---

  17. Repeat steps 9-16 for this tax line:
    - Search Tax Jurisdictions for: NEW YORK CITY CITY T, then NYC, then NEW YORK CITY, then CITY
    - Verify/create Tax Detail with Tax Group Code = TAXABLE, Tax Below Maximum = 4.50
    - If creating new: Code = NYCTAX, Description = New York City City T
    - Assign to the tax line

  --- Tax Line 3: "METROPOLITAN COMMUTE" (0.38%) ---

  18. Repeat steps 9-16 for this tax line:
    - Search Tax Jurisdictions for: METROPOLITAN COMMUTE, then MTA, then METRO, then COMMUTER
    - Verify/create Tax Detail with Tax Group Code = TAXABLE, Tax Below Maximum = 0.38
    - If creating new: Code = MTATAX, Description = Metropolitan Commute
    - Assign to the tax line

  ---
  Step 4: Find or create a Tax Area

  Now you need a Tax Area that contains exactly NYSTAX + NYCTAX + MTATAX (no more, no fewer).

  19. From the role center, click "Tax Area List" (page 469)
  20. Open each Tax Area card and check its Lines subpart:
    - Does it have exactly 3 lines: NYSTAX, NYCTAX, and MTATAX?
    - If yes: note the Tax Area Code, skip to step 26
  21. If no matching Tax Area exists, click New (this opens the Tax Area card, page 464)
  22. Set:
    - Code: SHPFY-AUTO-1
    - Description: Shopify - NY State+NYC+MTA
  23. In the Lines subpart, add first row:
    - Tax Jurisdiction Code: NYSTAX
    - Calculation Order: 1
  24. Add second row:
    - Tax Jurisdiction Code: NYCTAX
    - Calculation Order: 2
  25. Add third row:
    - Tax Jurisdiction Code: MTATAX
    - Calculation Order: 3
  26. Close the card (or press Escape) — the Tax Area is saved

  ---
  Step 5: Assign Tax Area and release the order

  27. Go back to the Shopify Order card for #1005
  28. Set Tax Area Code = SHPFY-AUTO-1 (or the existing Tax Area Code you found)
  29. Set On Hold = No (uncheck)
  30. Verify both fields are saved
  31. If the "Create Sales Document" action is visible, click it

  Important: Set Tax Area Code FIRST, then release. The standard connector will skip its address-based lookup because Tax Area Code is already set.

  ---
  Step 6 (Optional): Save mapping for future orders

  32. From the role center, click "Shopify Shops", open the TEST shop
  33. In the Navigation menu, click "Customer Setup by Country/Region"
  34. On the Shopify Customer Templates page, select the row for Country/Region Code = US
  35. In the Shopify Tax Areas subpart at the bottom, check if a row exists for County = NY
  36. If not, add a new row:
    - County: NY
    - Tax Area Code: SHPFY-AUTO-1
    - Tax Liable: Yes
  37. Close the page

  This means future orders shipping to US/NY will automatically get SHPFY-AUTO-1 without needing the agent.

  ---
  Step 7: Verify the result

  38. Go back to the Shopify Order for #1005
  39. Confirm:
    - Tax Area Code = SHPFY-AUTO-1
    - On Hold = No
    - Click Tax Lines and verify:
      - Tax line 1 (NEW YORK STATE TAX): Tax Jurisdiction Code = NYSTAX
      - Tax line 2 (NEW YORK CITY CITY T): Tax Jurisdiction Code = NYCTAX
      - Tax line 3 (METROPOLITAN COMMUTE): Tax Jurisdiction Code = MTATAX
  40. Open Tax Jurisdictions, select each new jurisdiction, and click Details to verify Tax Details exist:
    - NYSTAX: Tax Group = TAXABLE, Tax Below Maximum = 4.00
    - NYCTAX: Tax Group = TAXABLE, Tax Below Maximum = 4.50
    - MTATAX: Tax Group = TAXABLE, Tax Below Maximum = 0.38
  41. Try processing the order into a sales document — it should succeed and the sales header should have Tax Area Code = SHPFY-AUTO-1

  ---
  Role Center Actions (Shpfy Tax Agent RC):
  - Shopify Orders -> page "Shpfy Orders" (30115)
  - Tax Jurisdictions -> page "Tax Jurisdictions" (466)
  - Tax Area List -> page "Tax Area List" (469)
  - Shopify Shops -> page "Shpfy Shops" (30102)

  Tax Lines Page Actions (agent-only):
  - Tax Jurisdictions -> page "Tax Jurisdictions" (466)

  ---
  Summary: The walkthrough covers the full agent flow. Step 1 is reviewing settings (no-op for agent — settings come from task message). Steps 2-3 are the core matching loop: for each tax line, find/create jurisdiction and verify/create Tax Details. Step 4 assembles the Tax Area. Step 5 assigns and releases. Step 6 is optional learning. Step 7 is verification.
