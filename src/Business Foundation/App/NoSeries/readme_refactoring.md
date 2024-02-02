# Refactoring to use the new No. Series module

This document is created to give a brief explanation of how refactor your code to use the new No. Series module.
Old refers to the current ways of using the No. Series implementation while New refers to using the newly created No. Series module.

## Uptake examples

### TryGetNextNo

Old:
```
DocNo := NoSeriesMgt.TryGetNextNo(GenJnlBatch."No. Series", EndDateReq);
```
New:
```
DocNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series", EndDateReq);
```

### GetNextNo with delayed modify

Old:
```
if DocNo := NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", EndDateReq, false) then
    NoSeriesMgt.SaveNoSeries();
```
New:
You have two options here, either you can Peek the next No. and update or use batch
```
if DocNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series", EndDateReq) then
    NoSeries.GetNextNo(GenJnlBatch."No. Series", EndDateReq);
```
or
```
if DocNo := NoSeriesBatch.GetNextNo(GenJnlBatch."No. Series", EndDateReq) then
    NoSeriesBatch.SaveState();
```

### InitSeries

Now InitSeries is a very complex implementation. In most cases where InitSeries is used, we verify that the given No. is not set, which this example will also verify. If it is, you will need to verify whether manual Nos are allowed.

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
    NoSeries.AreRelated(GLSetup."Bank Account Nos.", xRec."No. Series") then
        "No. Series" := xRec."No. Series"
    "No." := NoSeries.GetNextNo("No. Series");
end;
```
The new style is a bit more lines but better describes what is happening. Furthermore to keep this backwards compatible with old events, please add calls to the obsoleted functions NoSeriesManagement.RaiseObsoleteOnBeforeInitSeries and NoSeriesManagement.RaiseObsoleteOnAfterInitSeries. Example:
```
if "No." = '' then begin
    GLSetup.Get();
    GLSetup.TestField("Bank Account Nos.");
    NoSeriesManagement.RaiseObsoleteOnBeforeInitSeries(GLSetup."Bank Account Nos.", xRec."No. Series", 0D, "No.", "No. Series", IsHandled);
    if not IsHandled then begin
        "No. Series" := GLSetup."Bank Account Nos.";
        NoSeries.AreRelated(GLSetup."Bank Account Nos.", xRec."No. Series") then
            "No. Series" := xRec."No. Series"
        "No." := NoSeries.GetNextNo("No. Series");
        NoSeriesManagement.RaiseObsoleteOnAfterInitSeries("No. Series", GLSetup."Bank Account Nos.", 0D, "No.");
    end;
end;
```

### Document posting with delayed modify
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

Sometimes we want to simulate using the No. Series without actually updating it and we may want to start from a specific No. For this purpose we added the SimulateGetNextNo function on the No. Series - Batch:

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
"Document No." := NoSeriesBatch.SimulateGetNextNo(GenJnlBatch."No. Series", Rec."Posting Date", "Document No.")
```

This new function will use the details of the given No. Series to increment the Document No. In case the No. Series does not exist, the Document No. will be increased by one.
