codeunit 160803 "Norwegian demo-adjustments"
{

    trigger OnRun()
    begin
        // Update VAT Code (forgotten in the demo objects):
        VATProdPostGrp.Get(xOUTSIDE);
        VATProdPostGrp."Outside Tax Area" := true;
        VATProdPostGrp.Modify();

        // Convert G/L Account
        ImportConvertScheme.Run();
        ImportAccSch.Run();
        ConvertGLAcc.RunModal();
        ConvertFormels.RunModal();
        IndentGLAcc.Indent();
        IndentGLAcc.IndentIC();
        GLAccConverted.DeleteAll();
        AccSchConverted.DeleteAll();
        AnalysisConverted.DeleteAll();
        CreatePmtTypeAbroad.Run();

        CreateDemostrationData.GetTableIDs(TempInteger);
        if TempInteger.Get(Database::"Acc. Schedules Conversion") then
            TempInteger.Delete();
        if TempInteger.Get(Database::"GL Accounts Conversion") then
            TempInteger.Delete();
        if TempInteger.Get(Database::"Analysis Conversion") then
            TempInteger.Delete();    
    end;

    var
        GLAccConverted: Record "GL Accounts Conversion";
        AccSchConverted: Record "Acc. Schedules Conversion";
        TempInteger: Record Integer temporary;
        AnalysisConverted: Record "Analysis Conversion";
        VATProdPostGrp: Record "VAT Product Posting Group";
        CreateDemostrationData: Codeunit "Create Demonstration Data";
        ImportConvertScheme: Codeunit "GL Account Convert Scheme";
        IndentGLAcc: Codeunit "G/L Account conveted -Indent";
        ImportAccSch: Codeunit "Import GLAcc. Scheme";
        CreatePmtTypeAbroad: Codeunit "Create Payment Type (abroad)";
        ConvertGLAcc: Report "Convert GL Accounts";
        ConvertFormels: Report "Convert Formulas";
        xOUTSIDE: Label 'OUTSIDE';

}

