# Extensibility

AI tools provide extensibility through AOAI Function interface and historical data customization.

## Add custom AI tool

Partners can add new AI tools by implementing AOAI Function and IEDocAISystem interfaces:

```al
codeunit 50100 "My AI Tool" implements "AOAI Function", IEDocAISystem
{
    // AOAI Function interface methods
    procedure GetPrompt(): JsonObject
    var
        Prompt: JsonObject;
        SystemMessage: JsonObject;
        Messages: JsonArray;
    begin
        // System prompt
        SystemMessage.Add('role', 'system');
        SystemMessage.Add('content', 'You are a custom data resolver...');
        Messages.Add(SystemMessage);

        Prompt.Add('messages', Messages);
        Prompt.Add('temperature', 0.1);
        Prompt.Add('max_tokens', 1000);

        exit(Prompt);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        Result: Text;
    begin
        // Extract parameters from Arguments
        // Perform resolution logic
        // Return result to AI
        exit(Result);
    end;

    procedure GetName(): Text
    begin
        exit('my_custom_tool');
    end;

    // IEDocAISystem interface methods
    procedure CanProcess(EDocument: Record "E-Document"): Boolean
    begin
        // Check if tool should run for this document
        exit(true);
    end;

    procedure Process(var EDocument: Record "E-Document")
    var
        EDocAIProcessor: Codeunit "E-Doc. AI Tool Processor";
        Response: Codeunit "AOAI Operation Response";
    begin
        // Setup AI processor
        if not EDocAIProcessor.Setup(this) then
            exit;

        // Call AOAI with user message
        if not EDocAIProcessor.Process(CreateUserMessage(EDocument), Response) then
            exit;

        // Process function responses
        ProcessResponses(Response);
    end;
}
```

Register tool via enum extension:

```al
enumextension 50100 "My AI Tool Enum" extends "AOAI Function"
{
    value(50100; "My Custom Tool")
    {
        Implementation = "AOAI Function" = "My AI Tool";
    }
}
```

Call tool during Prepare step via event:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Prepare Purchase E-Doc. Draft", 'OnAfterMasterDataResolution', '', false, false)]
local procedure OnAfterMasterDataResolution(var EDocument: Record "E-Document")
var
    MyAITool: Codeunit "My AI Tool";
begin
    if MyAITool.CanProcess(EDocument) then
        MyAITool.Process(EDocument);
end;
```

## Customize historical data

Partners can extend historical matching by adding custom history tables:

```al
table 50100 "My Purchase History"
{
    fields
    {
        field(1; "Description Hash"; Code[50]) { }
        field(2; "Description"; Text[250]) { }
        field(3; "My Custom Field"; Code[20]) { }
        field(4; "Use Count"; Integer) { }
        field(5; "Last Used Date"; DateTime) { }
    }
}

codeunit 50101 "My Historical Matching" implements IEDocAISystem
{
    procedure Process(var EDocument: Record "E-Document")
    var
        MyHistory: Record "My Purchase History";
        EDocPurchaseLine: Record "E-Document Purchase Line";
    begin
        // Query custom history
        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if EDocPurchaseLine.FindSet() then
            repeat
                MyHistory.SetRange("Description Hash", CalcHash(EDocPurchaseLine.Description));
                if MyHistory.FindFirst() then begin
                    // Apply historical assignment
                    EDocPurchaseLine."My Custom Field" := MyHistory."My Custom Field";
                    EDocPurchaseLine.Modify();
                end;
            until EDocPurchaseLine.Next() = 0;
    end;
}
```

Rebuild history via batch job:

```al
codeunit 50102 "Rebuild My History"
{
    trigger OnRun()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        MyHistory: Record "My Purchase History";
        Hash: Code[50];
    begin
        // Clear old history
        MyHistory.DeleteAll();

        // Analyze last 90 days
        PurchInvLine.SetFilter("Posting Date", '>=%1', CalcDate('-90D', Today));
        if PurchInvLine.FindSet() then
            repeat
                Hash := CalcHash(PurchInvLine.Description);
                if MyHistory.Get(Hash) then begin
                    MyHistory."Use Count" += 1;
                    MyHistory."Last Used Date" := CurrentDateTime;
                    MyHistory.Modify();
                end else begin
                    MyHistory.Init();
                    MyHistory."Description Hash" := Hash;
                    MyHistory.Description := PurchInvLine.Description;
                    MyHistory."My Custom Field" := PurchInvLine."My Custom Field";
                    MyHistory."Use Count" := 1;
                    MyHistory."Last Used Date" := CurrentDateTime;
                    MyHistory.Insert();
                end;
            until PurchInvLine.Next() = 0;
    end;

    local procedure CalcHash(Description: Text[250]): Code[50]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        exit(CopyStr(CryptographyManagement.GenerateHash(Description, 'SHA256'), 1, 50));
    end;
}
```

## Customize confidence thresholds

Partners can override default confidence thresholds per tool:

```al
tableextension 50100 "My AI Config Ext" extends "E-Document Service"
{
    fields
    {
        field(50100; "My AI Tool Threshold"; Decimal)
        {
            Caption = 'My AI Tool Threshold';
            InitValue = 0.7;
            MinValue = 0.0;
            MaxValue = 1.0;
        }
    }
}

codeunit 50100 "My AI Tool" implements "AOAI Function", IEDocAISystem
{
    procedure Process(var EDocument: Record "E-Document")
    var
        EDocService: Record "E-Document Service";
        Confidence: Decimal;
        Threshold: Decimal;
    begin
        EDocService := EDocument.GetEDocumentService();
        Threshold := EDocService."My AI Tool Threshold";

        // Apply suggestions above threshold
        if Confidence >= Threshold then
            ApplySuggestion();
    end;
}
```

## Add custom grounding

Partners can implement custom grounding logic to teach AI from user feedback:

```al
codeunit 50103 "My Grounding Logic"
{
    procedure BuildGroundingContext(EDocument: Record "E-Document"): Text
    var
        ActivityLog: Record "Activity Log";
        Context: TextBuilder;
    begin
        // Query user feedback for this vendor
        ActivityLog.SetRange("Record ID", EDocument.RecordId);
        ActivityLog.SetRange("Activity Type", ActivityLog."Activity Type"::AI);
        ActivityLog.SetFilter("Activity Date", '>=%1', CalcDate('-30D', Today));

        Context.AppendLine('Previous AI suggestions for this vendor:');

        if ActivityLog.FindSet() then
            repeat
                if ActivityLog."User Confirmed" then
                    Context.AppendLine(StrSubstNo('- %1 (Accepted)', ActivityLog.Description))
                else
                    Context.AppendLine(StrSubstNo('- %1 (Rejected: %2)', ActivityLog.Description, ActivityLog."Rejection Reason"));
            until ActivityLog.Next() = 0;

        exit(Context.ToText());
    end;

    procedure ApplyGrounding(var Prompt: JsonObject; EDocument: Record "E-Document")
    var
        Messages: JsonArray;
        GroundingMessage: JsonObject;
    begin
        Prompt.Get('messages', Messages);

        // Add grounding context as assistant message
        GroundingMessage.Add('role', 'assistant');
        GroundingMessage.Add('content', BuildGroundingContext(EDocument));
        Messages.Add(GroundingMessage);

        Prompt.Replace('messages', Messages);
    end;
}
```

Include grounding in tool prompt:

```al
procedure GetPrompt(): JsonObject
var
    Prompt: JsonObject;
    MyGrounding: Codeunit "My Grounding Logic";
begin
    Prompt := GetBasePrompt();
    MyGrounding.ApplyGrounding(Prompt, Rec);
    exit(Prompt);
end;
```

## Testing AI tools

Test AI tools using mock AOAI responses:

```al
codeunit 50199 "My AI Tool Test"
{
    [Test]
    procedure TestGLAccountSuggestion()
    var
        EDocument: Record "E-Document";
        EDocPurchaseLine: Record "E-Document Purchase Line";
        MyAITool: Codeunit "My AI Tool";
        MockAOAI: Codeunit "Mock AOAI";
    begin
        // Setup test data
        CreateTestEDocument(EDocument);
        CreateTestLine(EDocPurchaseLine);

        // Mock AOAI response
        MockAOAI.SetResponse('{
            "function_calls": [{
                "name": "CreateSuggestion",
                "arguments": {"glAccountNo": "5100", "confidence": 0.85}
            }]
        }');

        // Execute tool
        MyAITool.Process(EDocument);

        // Verify suggestion applied
        EDocPurchaseLine.Find();
        Assert.AreEqual('5100', EDocPurchaseLine."[BC] Purchase Type No.", 'GL Account not assigned');
    end;
}
```

Mock codeunit intercepts AOAI calls and returns test responses without actual API calls.

## Performance monitoring

Monitor AI tool performance via telemetry:

```al
codeunit 50104 "My AI Tool Monitor"
{
    procedure LogPerformance(ToolName: Text; TokenCount: Integer; Duration: Duration; Confidence: Decimal)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('ToolName', ToolName);
        Dimensions.Add('TokenCount', Format(TokenCount));
        Dimensions.Add('Duration', Format(Duration));
        Dimensions.Add('Confidence', Format(Confidence));

        FeatureTelemetry.LogUsage('0000XYZ', 'AI Tool Execution', Dimensions);
    end;

    procedure AnalyzeCostPerMatch()
    var
        TelemetryData: Query "AI Tool Telemetry";
        TotalCost: Decimal;
        MatchCount: Integer;
    begin
        // Query aggregated telemetry
        TelemetryData.Open();
        while TelemetryData.Read() do begin
            TotalCost += TelemetryData.TokenCount * 0.00001; // GPT-4 pricing
            MatchCount += 1;
        end;

        Message('Average cost per match: $%1', TotalCost / MatchCount);
    end;
}
```

Use telemetry to optimize prompt efficiency and identify expensive tools for review.
