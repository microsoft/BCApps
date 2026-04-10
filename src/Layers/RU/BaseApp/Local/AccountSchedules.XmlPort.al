#pragma warning disable AA0247
xmlport 26552 "Account Schedules"
{
    Caption = 'Account Schedules';
    Encoding = UTF8;

    schema
    {
        textelement(AccountSchedules)
        {
            MaxOccurs = Once;
            tableelement("acc. schedule name"; "Acc. Schedule Name")
            {
                MinOccurs = Zero;
                XmlName = 'AccScheduleName';
                UseTemporary = true;
                fieldelement(Name; "Acc. Schedule Name".Name)
                {
                    MinOccurs = Zero;
                }
                fieldelement(Description; "Acc. Schedule Name".Description)
                {
                    MinOccurs = Zero;
                }
                fieldelement(AnalysisViewName; "Acc. Schedule Name"."Analysis View Name")
                {
                    MinOccurs = Zero;
                }
                tableelement("acc. schedule line"; "Acc. Schedule Line")
                {
                    LinkFields = "Schedule Name" = field(Name);
                    LinkTable = "Acc. Schedule Name";
                    MinOccurs = Zero;
                    XmlName = 'AccScheduleLine';
                    UseTemporary = true;
                    fieldelement(ScheduleName; "Acc. Schedule Line"."Schedule Name")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(LineNo; "Acc. Schedule Line"."Line No.")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(RowNo; "Acc. Schedule Line"."Row No.")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Description; "Acc. Schedule Line".Description)
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ExtensionSourceTable; "Acc. Schedule Line"."Extension Source Table")
                    {
                    }
                    fieldelement(Totaling; "Acc. Schedule Line".Totaling)
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(TotalingType; "Acc. Schedule Line"."Totaling Type")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(NewPage; "Acc. Schedule Line"."New Page")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Show; "Acc. Schedule Line".Show)
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Dimension1Totaling; "Acc. Schedule Line"."Dimension 1 Totaling")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Dimension2Totaling; "Acc. Schedule Line"."Dimension 2 Totaling")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Dimension3Totaling; "Acc. Schedule Line"."Dimension 3 Totaling")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Dimension4Totaling; "Acc. Schedule Line"."Dimension 4 Totaling")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Bold; "Acc. Schedule Line".Bold)
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Italic; "Acc. Schedule Line".Italic)
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Underline; "Acc. Schedule Line".Underline)
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ShowOppositeSign; "Acc. Schedule Line"."Show Opposite Sign")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(RowType; "Acc. Schedule Line"."Row Type")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(AmountType; "Acc. Schedule Line"."Amount Type")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(CorrTotaling; "Acc. Schedule Line"."Corr. Totaling")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Dimension1CorrTotaling; "Acc. Schedule Line"."Dimension 1 Corr. Totaling")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Dimension2CorrTotaling; "Acc. Schedule Line"."Dimension 2 Corr. Totaling")
                    {
                        MinOccurs = Zero;
                    }
                }
            }
            tableelement("column layout name"; "Column Layout Name")
            {
                MinOccurs = Zero;
                XmlName = 'ColumnLayoutName';
                UseTemporary = true;
                fieldelement(Name; "Column Layout Name".Name)
                {
                    MinOccurs = Zero;
                }
                fieldelement(Description; "Column Layout Name".Description)
                {
                    MinOccurs = Zero;
                }
                fieldelement(AnalysisViewName; "Column Layout Name"."Analysis View Name")
                {
                    MinOccurs = Zero;
                }
                tableelement("column layout"; "Column Layout")
                {
                    LinkFields = "Column Layout Name" = field(Name);
                    LinkTable = "Column Layout Name";
                    MinOccurs = Zero;
                    XmlName = 'ColumnLayout';
                    UseTemporary = true;
                    fieldelement(ColumnLayoutName; "Column Layout"."Column Layout Name")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(LineNo; "Column Layout"."Line No.")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ColumnNo; "Column Layout"."Column No.")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ColumnHeader; "Column Layout"."Column Header")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ColumnType; "Column Layout"."Column Type")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(LedgerEntryType; "Column Layout"."Ledger Entry Type")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(AmountType; "Column Layout"."Amount Type")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Formula; "Column Layout".Formula)
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ComparisonDateFormula; "Column Layout"."Comparison Date Formula")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ShowOppositeSign; "Column Layout"."Show Opposite Sign")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Show; "Column Layout".Show)
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(RoundingFactor; "Column Layout"."Rounding Factor")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ComparisonPeriodFormula; "Column Layout"."Comparison Period Formula")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(BusinessUnitTotaling; "Column Layout"."Business Unit Totaling")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Dimension1Totaling; "Column Layout"."Dimension 1 Totaling")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Dimension2Totaling; "Column Layout"."Dimension 2 Totaling")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Dimension3Totaling; "Column Layout"."Dimension 3 Totaling")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Dimension4Totaling; "Column Layout"."Dimension 4 Totaling")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Dimension1CorrTotaling; "Column Layout"."Dimension 1 Corr. Totaling")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Dimension2CorrTotaling; "Column Layout"."Dimension 2 Corr. Totaling")
                    {
                        MinOccurs = Zero;
                    }
                }
            }
            tableelement("acc. schedule extension"; "Acc. Schedule Extension")
            {
                LinkTable = "Acc. Schedule Line";
                MinOccurs = Zero;
                XmlName = 'AccScheduleExtension';
                UseTemporary = true;
                fieldelement(Code; "Acc. Schedule Extension".Code)
                {
                    MinOccurs = Zero;
                }
                fieldelement(Description; "Acc. Schedule Extension".Description)
                {
                    MinOccurs = Zero;
                }
                fieldelement(SourceTable; "Acc. Schedule Extension"."Source Table")
                {
                    MinOccurs = Zero;
                }
                fieldelement(AmountSign; "Acc. Schedule Extension"."Amount Sign")
                {
                    MinOccurs = Zero;
                }
                fieldelement(VATEntryType; "Acc. Schedule Extension"."VAT Entry Type")
                {
                    MinOccurs = Zero;
                }
                fieldelement(PrepaymentFilter; "Acc. Schedule Extension"."Prepayment Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(ReverseSign; "Acc. Schedule Extension"."Reverse Sign")
                {
                    MinOccurs = Zero;
                }
                fieldelement(VATAmountType; "Acc. Schedule Extension"."VAT Amount Type")
                {
                    MinOccurs = Zero;
                }
                fieldelement(VATBusPostGroupFilter; "Acc. Schedule Extension"."VAT Bus. Post. Group Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(VATProdPostGroupFilter; "Acc. Schedule Extension"."VAT Prod. Post. Group Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(VATType; "Acc. Schedule Extension"."VAT Type")
                {
                    MinOccurs = Zero;
                }
                fieldelement(LiabilityType; "Acc. Schedule Extension"."Liability Type")
                {
                    MinOccurs = Zero;
                }
                fieldelement(LocationFilter; "Acc. Schedule Extension"."Location Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(BinFilter; "Acc. Schedule Extension"."Bin Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(ValueEntryTypeFilter; "Acc. Schedule Extension"."Value Entry Type Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(InventoryPostingGroupFilter; "Acc. Schedule Extension"."Inventory Posting Group Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(ItemChargeNoFilter; "Acc. Schedule Extension"."Item Charge No. Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(ValueEntryAmountType; "Acc. Schedule Extension"."Value Entry Amount Type")
                {
                    MinOccurs = Zero;
                }
                fieldelement(PostingGroupFilter; "Acc. Schedule Extension"."Posting Group Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(PostingDateFilter; "Acc. Schedule Extension"."Posting Date Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(DueDateFilter; "Acc. Schedule Extension"."Due Date Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(DocumentTypeFilter; "Acc. Schedule Extension"."Document Type Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(GenBusPostGroupFilter; "Acc. Schedule Extension"."Gen. Bus. Post. Group Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(GenProdPostGroupFilter; "Acc. Schedule Extension"."Gen. Prod. Post. Group Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(ObjectTypeFilter; "Acc. Schedule Extension"."Object Type Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(ObjectNoFilter; "Acc. Schedule Extension"."Object No. Filter")
                {
                    MinOccurs = Zero;
                }
                fieldelement(VATAllocationTypeFilter; "Acc. Schedule Extension"."VAT Allocation Type Filter")
                {
                    MinOccurs = Zero;
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        AccScheduleExtension: Record "Acc. Schedule Extension";

    [Scope('OnPrem')]
    procedure SetData(var TempAccScheduleName: Record "Acc. Schedule Name")
    begin
        "Acc. Schedule Name".Reset();
        "Acc. Schedule Name".DeleteAll();
        if TempAccScheduleName.FindSet() then
            repeat
                "Acc. Schedule Name" := TempAccScheduleName;
                "Acc. Schedule Name".Insert();

                AccScheduleLine.SetRange("Schedule Name", TempAccScheduleName.Name);
                if AccScheduleLine.FindSet() then
                    repeat
                        "Acc. Schedule Line" := AccScheduleLine;
                        "Acc. Schedule Line".Insert();

                        if (AccScheduleLine."Totaling Type" = AccScheduleLine."Totaling Type"::Custom) and
                           (AccScheduleLine.Totaling <> '')
                        then
                            if not "Acc. Schedule Extension".Get(AccScheduleLine.Totaling) then begin
                                AccScheduleExtension.Get(AccScheduleLine.Totaling);
                                "Acc. Schedule Extension" := AccScheduleExtension;
                                "Acc. Schedule Extension".Insert();
                            end;
                    until AccScheduleLine.Next() = 0;

            until TempAccScheduleName.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportData()
    begin
        "Acc. Schedule Name".Reset();
        if "Acc. Schedule Name".FindSet() then
            repeat
                if AccScheduleName.Get("Acc. Schedule Name".Name) then
                    AccScheduleName.Delete(true);
                AccScheduleName := "Acc. Schedule Name";
                AccScheduleName.Insert();
            until "Acc. Schedule Name".Next() = 0;

        "Acc. Schedule Line".Reset();
        if "Acc. Schedule Line".FindSet() then
            repeat
                if AccScheduleLine.Get("Acc. Schedule Line"."Schedule Name", "Acc. Schedule Line"."Line No.") then
                    AccScheduleLine.Delete(true);
                AccScheduleLine := "Acc. Schedule Line";
                AccScheduleLine.Insert();
            until "Acc. Schedule Line".Next() = 0;

        "Acc. Schedule Extension".Reset();
        if "Acc. Schedule Extension".FindSet() then
            repeat
                if AccScheduleExtension.Get("Acc. Schedule Extension".Code) then
                    AccScheduleExtension.Delete(true);
                AccScheduleExtension := "Acc. Schedule Extension";
                AccScheduleExtension.Insert();
            until "Acc. Schedule Extension".Next() = 0;
    end;
}

