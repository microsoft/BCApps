# Refactoring to use the new No. Series module

This document provides brief explanations and some examples that can help you refactor your code to use the new No. Series module.
Each section offers examples of the old and new ways of using the No. Series implementation. "Old" refers to how we currently do that, and "New" refers to using the new No. Series module.

## Uptake examples

### TryGetNextNo
TryGetNextNo is a function that gets and returns the next number, without modifying the No. Series. PeekNextNo does the same now and makes the code easier to understand.

Old:
```
DocNo := NoSeriesMgt.TryGetNextNo(GenJnlBatch."No. Series", EndDateReq);
```
New:
```
DocNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series", EndDateReq);
```

### GetNextNo with delayed modify

> [!WARNING]  
> The procedure ``GetNextNo(Code[20]; Date; Boolean)`` exists in the legacy and in the new codeunit with the same signature but **logically different behavior**: The boolean parameter within the legacy procedure controls whether the requested number of the No. Series should be saved in the database, while the boolean in the new procedure hides errors and warnings.

Old:
```
if DocNo = NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", EndDateReq, false) then
    NoSeriesMgt.SaveNoSeries();
```
New:
You have two options here. Either you Peek the next number and update, or use a batch. This depends on the use case, but by using a batch you ensure that the number saved to the database is the DocNo.
```
if DocNo = NoSeries.PeekNextNo(GenJnlBatch."No. Series", EndDateReq) then
    NoSeries.GetNextNo(GenJnlBatch."No. Series", EndDateReq);
```
or
```
if DocNo = NoSeriesBatch.GetNextNo(GenJnlBatch."No. Series", EndDateReq) then
    NoSeriesBatch.SaveState();
```

### InitSeries

InitSeries is a complex implementation because it handles multiple cases. In most cases that use InitSeries, we verify that the given number isn't set, as shown in the following example. If it is, you'll need to verify whether manual numbers are allowed (see IsManual or TestManual procedures in the No. Series codeunit).

Old:
```
if "No." = '' then begin
    GLSetup.Get();
    GLSetup.TestField("Bank Account Nos.");
    NoSeriesMgt.InitSeries(GLSetup."Bank Account Nos.", xRec."No. Series", 0D, "No.", "No. Series");
end;
```
New:
```
if "No." = '' then begin
    GLSetup.Get();
    GLSetup.TestField("Bank Account Nos.");
    "No. Series" := GLSetup."Bank Account Nos.";
    if NoSeries.AreRelated(GLSetup."Bank Account Nos.", xRec."No. Series") then
        "No. Series" := xRec."No. Series";
    "No." := NoSeries.GetNextNo("No. Series");
end;
```
The new style has a few more lines, but it also better describes what's happening.

To keep your code backwards compatible with old events that you or other partners may use, add calls to the obsoleted functions NoSeriesManagement.RaiseObsoleteOnBeforeInitSeries and NoSeriesManagement.RaiseObsoleteOnAfterInitSeries. Example:
```
if "No." = '' then begin
    GLSetup.Get();
    GLSetup.TestField("Bank Account Nos.");
    NoSeriesManagement.RaiseObsoleteOnBeforeInitSeries(GLSetup."Bank Account Nos.", xRec."No. Series", 0D, "No.", "No. Series", IsHandled);
    if not IsHandled then begin
        "No. Series" := GLSetup."Bank Account Nos.";
        if NoSeries.AreRelated(GLSetup."Bank Account Nos.", xRec."No. Series") then
            "No. Series" := xRec."No. Series";
        "No." := NoSeries.GetNextNo("No. Series");
        NoSeriesManagement.RaiseObsoleteOnAfterInitSeries("No. Series", GLSetup."Bank Account Nos.", 0D, "No.");
    end;
end;
```

### Document posting with delayed modify
During posting we often want to delay the update of No. Series. Currently the only way to do this for multiple No. Series is to use an array of NoSeriesManagement and find the correct one during posting. This is very confusing and not very readable. Using the new Batch codeunit, you only need to define a single codeunit, request new number for your different number series and posting dates. Finally, save the state and all records are updated.

Old:
```
var
    NoSeriesMgt2: array[100] of Codeunit NoSeriesManagement;
...
with GenJnlLine2 do
    if not TempNoSeries.Get("Posting No. Series") then begin
        NoOfPostingNoSeries := NoOfPostingNoSeries + 1;
        if NoOfPostingNoSeries > ArrayLen(NoSeriesMgt2) then
            Error(Text025, ArrayLen(NoSeriesMgt2));
        TempNoSeries.Code := "Posting No. Series";
        TempNoSeries.Description := Format(NoOfPostingNoSeries);
        TempNoSeries.Insert();
    end;
    LastDocNo := "Document No.";
    Evaluate(PostingNoSeriesNo, TempNoSeries.Description);
    "Document No." := NoSeriesMgt2[PostingNoSeriesNo].GetNextNo("Posting No. Series", "Posting Date", true);
    LastPostedDocNo := "Document No.";
```
New:
```
var
    NoSeriesBatch: Codeunit "No. Series - Batch";
...
LastDocNo := GenJnlLine2."Document No.";
GenJnlLine2."Document No." := NoSeriesBatch.GetNextNo(GenJnlLine2."Posting No. Series", GenJnlLine2."Posting Date");
LastPostedDocNo := GenJnlLine2."Document No.";
...
NoSeriesBatch.SaveState();
```
### Simulating new numbers

Sometimes we want to simulate the use of No. Series without actually updating it, and we may want to start from a specific number. For this purpose, we added the SimulateGetNextNo function on the No. Series - Batch.

Old:
```
procedure IncrementDocumentNo(GenJnlBatch: Record "Gen. Journal Batch"; var LastDocNumber: Code[20])
var
    NoSeriesLine: Record "No. Series Line";
begin
    if GenJnlBatch."No. Series" <> '' then begin
        NoSeriesManagement.SetNoSeriesLineFilter(NoSeriesLine, GenJnlBatch."No. Series", "Posting Date");
        if NoSeriesLine."Increment-by No." > 1 then
            NoSeriesManagement.IncrementNoText(LastDocNumber, NoSeriesLine."Increment-by No.")
        else
            LastDocNumber := IncStr(LastDocNumber);
    end else
        LastDocNumber := IncStr(LastDocNumber);
end;
```
New:
```
"Document No." := NoSeriesBatch.SimulateGetNextNo(GenJnlBatch."No. Series", Rec."Posting Date", "Document No.");
```

This new function uses the details of the given number series to increment the document number. If the number series doesn't exist, the document number increases by one.
