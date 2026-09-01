#pragma warning disable AA0247
table 17221 "Tax Register Norm Group"
{
    Caption = 'Tax Register Norm Group';
    LookupPageID = "Tax Register Norm Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Norm Jurisdiction Code"; Code[10])
        {
            Caption = 'Norm Jurisdiction Code';
            NotBlank = true;
            TableRelation = "Tax Register Norm Jurisdiction";
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(4; "Has Details"; Boolean)
        {
            CalcFormula = exist("Tax Register Norm Detail" where("Norm Jurisdiction Code" = field("Norm Jurisdiction Code"),
                                                                  "Norm Group Code" = field(Code)));
            Caption = 'Has Details';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Search Detail"; Option)
        {
            Caption = 'Search Detail';
            OptionCaption = 'To Date,As of Date';
            OptionMembers = "To Date","As of Date";

            trigger OnValidate()
            begin
                if "Search Detail" = "Search Detail"::"To Date" then
                    TestField("Storing Method", "Storing Method"::" ");
            end;
        }
        field(6; "Storing Method"; Option)
        {
            Caption = 'Storing Method';
            OptionCaption = ' ,Calculation';
            OptionMembers = " ",Calculation;

            trigger OnValidate()
            var
                TaxRegNormTemplateLine: Record "Tax Reg. Norm Template Line";
                TaxRegNormAccumulation: Record "Tax Reg. Norm Accumulation";
                TaxRegNormTerm: Record "Tax Reg. Norm Term";
            begin
                if ("Storing Method" <> xRec."Storing Method") and (xRec."Storing Method" = xRec."Storing Method"::Calculation) then begin
                    TaxRegNormTemplateLine.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
                    TaxRegNormTemplateLine.SetRange("Norm Group Code", Code);
                    if TaxRegNormTemplateLine.FindFirst() then
                        if not Confirm(Text1000, false) then
                            Error('');
                    TaxRegNormTemplateLine.DeleteAll(true);
                    TaxRegNormAccumulation.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
                    TaxRegNormAccumulation.SetRange("Norm Group Code", Code);
                    TaxRegNormAccumulation.DeleteAll(true);
                end;
                if "Storing Method" = "Storing Method"::Calculation then begin
                    "Search Detail" := "Search Detail"::"As of Date";
                    TaxRegNormTemplateLine.GenerateProfile();
                    TaxRegNormTerm.GenerateProfile();
                end;
            end;
        }
        field(7; Check; Boolean)
        {
            Caption = 'Check';
            Editable = false;
        }
        field(8; Level; Integer)
        {
            Caption = 'Level';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Norm Jurisdiction Code", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Has Details", "Search Detail", "Storing Method")
        {
        }
    }

    trigger OnDelete()
    var
        TaxRegNormDetail: Record "Tax Register Norm Detail";
        TaxRegNormTemplateLine: Record "Tax Reg. Norm Template Line";
        TaxRegNormAccumulation: Record "Tax Reg. Norm Accumulation";
    begin
        TaxRegNormDetail.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
        TaxRegNormDetail.SetRange("Norm Group Code", Code);
        TaxRegNormDetail.DeleteAll(true);

        TaxRegNormTemplateLine.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
        TaxRegNormTemplateLine.SetRange("Norm Group Code", Code);
        TaxRegNormTemplateLine.DeleteAll(true);

        TaxRegNormAccumulation.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
        TaxRegNormAccumulation.SetRange("Norm Group Code", Code);
        TaxRegNormAccumulation.DeleteAll(true);
    end;

    var
#pragma warning disable AA0074
        Text1000: Label 'Template Lines and Accumulation Lines will be deleted.\\Continue?';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure CalcDinamicNorm(StartDate: Date; EndDate: Date; NormJurisdictionCode: Code[10]; NormCode: Code[10]; SourceAmount: Decimal) ResultAmount: Decimal
    var
        TaxRegNormGroup: Record "Tax Register Norm Group";
        TaxRegNormTemplateLine: Record "Tax Reg. Norm Template Line";
        TaxRegNormAccumulation: Record "Tax Reg. Norm Accumulation";
        TaxRegNormDetail: Record "Tax Register Norm Detail";
        TaxRegValueBuffer: Record "Drop Shpt. Post. Buffer" temporary;
        EntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        TemplateRecordRef: RecordRef;
        LinkAccumulateRecordRef: RecordRef;
    begin
        TaxRegNormGroup.Get(NormJurisdictionCode, NormCode);

        TaxRegNormTemplateLine.Reset();
        TaxRegNormTemplateLine.SetRange("Norm Jurisdiction Code", NormJurisdictionCode);
        TaxRegNormTemplateLine.SetRange("Norm Group Code", TaxRegNormGroup.Code);
        TaxRegNormTemplateLine.SetRange("Date Filter", StartDate, EndDate);

        LinkAccumulateRecordRef.Open(DATABASE::"Tax Reg. Norm Accumulation");

        TaxRegNormAccumulation.SetCurrentKey("Norm Jurisdiction Code", "Norm Group Code", "Template Line No.");
        TaxRegNormAccumulation.SetRange("Norm Jurisdiction Code", NormJurisdictionCode);
        TaxRegNormAccumulation.SetRange("Ending Date", EndDate);
        LinkAccumulateRecordRef.SetView(TaxRegNormAccumulation.GetView());
        TaxRegNormAccumulation.SetRange("Norm Group Code", TaxRegNormGroup.Code);

        TaxRegValueBuffer."Order No." := TaxRegNormGroup.Code;

        TaxRegNormTemplateLine.SetRange("Line Type", TaxRegNormTemplateLine."Line Type"::"Amount for Norm");
        TaxRegNormTemplateLine.FindFirst();
        TaxRegNormTemplateLine.SetFilter("Line Code", '<>''''');
        TaxRegNormTemplateLine.SetFilter("Line Type", '<>%1', TaxRegNormTemplateLine."Line Type"::"Norm Value");
        if TaxRegNormTemplateLine.Find('-') then
            repeat
                if TaxRegNormTemplateLine."Line Type" = TaxRegNormTemplateLine."Line Type"::"Amount for Norm" then
                    TaxRegValueBuffer.Quantity := SourceAmount
                else begin
                    TaxRegNormAccumulation.SetRange("Template Line No.", TaxRegNormTemplateLine."Line No.");
                    TaxRegNormAccumulation.FindFirst();
                    TaxRegValueBuffer.Quantity := TaxRegNormAccumulation.Amount;
                end;
                TaxRegValueBuffer."Order Line No." := TaxRegNormTemplateLine."Line No.";
                TaxRegValueBuffer.Insert();
            until TaxRegNormTemplateLine.Next(1) = 0;
        TaxRegNormTemplateLine.SetRange("Line Type");
        TaxRegNormTemplateLine.SetRange("Line Code");
        TemplateRecordRef.GetTable(TaxRegNormTemplateLine);
        TemplateRecordRef.SetView(TaxRegNormTemplateLine.GetView());
        TaxRegTermMgt.CalculateTemplateEntry(
          TemplateRecordRef, EntryNoAmountBuffer, LinkAccumulateRecordRef, TaxRegValueBuffer);
        EntryNoAmountBuffer.Reset();
        if EntryNoAmountBuffer.Find('-') then
            repeat
                TaxRegNormAccumulation.SetRange("Template Line No.", EntryNoAmountBuffer."Entry No.");
                TaxRegNormAccumulation.FindFirst();
                TaxRegNormAccumulation.Amount := EntryNoAmountBuffer.Amount;
                TaxRegNormAccumulation.Modify();
                TaxRegNormTemplateLine.Get(NormJurisdictionCode, NormCode, TaxRegNormAccumulation."Template Line No.");
                if TaxRegNormTemplateLine."Line Type" = TaxRegNormTemplateLine."Line Type"::"Norm Value" then begin
                    ResultAmount := TaxRegNormAccumulation.Amount;
                    TaxRegNormDetail.Init();
                    TaxRegNormDetail."Norm Jurisdiction Code" := NormJurisdictionCode;
                    TaxRegNormDetail."Norm Group Code" := NormCode;
                    TaxRegNormDetail."Norm Type" := TaxRegNormDetail."Norm Type"::Amount;
                    TaxRegNormDetail."Effective Date" := EndDate;
                    TaxRegNormDetail.Norm := ResultAmount;
                    if not TaxRegNormDetail.Insert() then
                        TaxRegNormDetail.Modify();
                end;
            until EntryNoAmountBuffer.Next(1) = 0;
        TaxRegValueBuffer.Reset();
        TaxRegValueBuffer.DeleteAll();
        EntryNoAmountBuffer.DeleteAll();
    end;
}

