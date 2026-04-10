codeunit 134057 "ERM VAT Report Line Relation"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Report] [Line Relation]
    end;

    var
        ErrorMessage: Label 'Filter not correct';
        Assert: Codeunit Assert;
        InsertError: Label 'The record in table %1 Relation already exists.', Comment = '%1=Table Caption;';

    [Test]
    [Scope('OnPrem')]
    procedure TestOnInsertTrigger()
    var
        TempVATReportLineRelation: Record "VAT Report Line Relation" temporary;
        VATReportLine: Record "VAT Report Line";
    begin
        TempVATReportLineRelation.Init();
        TempVATReportLineRelation."VAT Report No." := 'Test';
        TempVATReportLineRelation."VAT Report Line No." := 1;
        TempVATReportLineRelation."Table No." := DATABASE::"VAT Entry";

        TempVATReportLineRelation.Insert(true);

        TempVATReportLineRelation."VAT Report No." := 'Test';
        TempVATReportLineRelation."VAT Report Line No." := 1;
        TempVATReportLineRelation."Table No." := DATABASE::"VAT Entry";

        asserterror TempVATReportLineRelation.Insert(true);
        Assert.ExpectedError(StrSubstNo(InsertError, VATReportLine.TableCaption()));

        TearDown(TempVATReportLineRelation."VAT Report No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateFilterForAmountMapping()
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
        TableNo: Integer;
    begin
        VATReportLineRelation."VAT Report No." := 'Test';
        VATReportLineRelation."VAT Report Line No." := 1;
        VATReportLineRelation."Line No." := 1;
        VATReportLineRelation."Table No." := DATABASE::"VAT Entry";
        VATReportLineRelation."Entry No." := 1;
        VATReportLineRelation.Insert(true);

        VATReportLineRelation."VAT Report No." := 'Test';
        VATReportLineRelation."VAT Report Line No." := 1;
        VATReportLineRelation."Line No." := 2;
        VATReportLineRelation."Table No." := DATABASE::"VAT Entry";
        VATReportLineRelation."Entry No." := 2;

        VATReportLineRelation.Insert(true);
        Assert.AreEqual('1|2', VATReportLineRelation.CreateFilterForAmountMapping('Test', 1, TableNo), ErrorMessage);

        TearDown('Test');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATStatementBoxNoIsVisible()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        VATStatement: TestPage "VAT Statement";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 295559] PAG 317 "VAT Statement" field "Box No." is visible
        if VATStatementName.FindFirst() then begin
            VATStatementLine."Statement Name" := VATStatementName.Name;
            VATStatementLine."Statement Template Name" := '';
            VATStatementLine.SetRange("Statement Template Name", VATStatementName."Statement Template Name");
        end;

        VATStatement.Trap();
        PAGE.Run(PAGE::"VAT Statement", VATStatementLine);
        Assert.IsTrue(VATStatement."Box No.".Visible(), 'VATStatement."Box No." should be visible');
        Assert.IsTrue(VATStatement."Box No.".Editable(), 'VATStatement."Box No." should be editable');
        VATStatement.Close();
    end;

    local procedure TearDown(VATReportNo: Code[20])
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        VATReportLineRelation.SetRange("VAT Report No.", VATReportNo);
        VATReportLineRelation.DeleteAll();
    end;
}

