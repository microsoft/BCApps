codeunit 101971 "Create Cue Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertDataForActivitiesCue();
        InsertDataForFinanceCue();
        InsertDataForSalesCue();
        InsertDataForRlshpMgmtCue();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then
            InsertDataForAdminCue();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CuesAndKPIs: Codeunit "Cues And KPIs";
        Style: Enum "Cues And KPIs Style";

    local procedure InsertDataForAdminCue()
    var
        CRMSynchJobStatusCue: Record "CRM Synch. Job Status Cue";
    begin
        CuesAndKPIs.InsertData(
          DATABASE::"CRM Synch. Job Status Cue",
          CRMSynchJobStatusCue.FieldNo("Failed Synch. Jobs"),
          Style::Favorable,
          0,// Threshold 1
          Style::None,
          0.01,// Threshold 2
          Style::Unfavorable);
    end;

    local procedure InsertDataForActivitiesCue()
    var
        ActivitiesCue: Record "Activities Cue";
    begin
        // Mini Activities Cue
        CuesAndKPIs.InsertData(
          DATABASE::"Activities Cue",
          ActivitiesCue.FieldNo("Ongoing Sales Invoices"),
          Style::None,
          15,// Threshold 1
          Style::Ambiguous,
          30,// Threshold 2
          Style::Unfavorable);

        CuesAndKPIs.InsertData(
          DATABASE::"Activities Cue",
          ActivitiesCue.FieldNo("Ongoing Purchase Invoices"),
          Style::None,
          15,// Threshold 1
          Style::Ambiguous,
          30,// Threshold 2
          Style::Unfavorable);

        CuesAndKPIs.InsertData(
          DATABASE::"Activities Cue",
          ActivitiesCue.FieldNo("Sales This Month"),
          Style::Ambiguous,
          1000,// Threshold 1
          Style::None,
          100000,// Threshold 2
          Style::Favorable);

        CuesAndKPIs.InsertData(
          DATABASE::"Activities Cue",
          ActivitiesCue.FieldNo("Top 10 Customer Sales YTD"),
          Style::Favorable,
          0.5,// Threshold 1
          Style::None,
          0.9,// Threshold 2
          Style::Unfavorable);

        CuesAndKPIs.InsertData(
          DATABASE::"Activities Cue",
          ActivitiesCue.FieldNo("Overdue Purch. Invoice Amount"),
          Style::Favorable,
          10000,// Threshold 1
          Style::Ambiguous,
          100000,// Threshold 2
          Style::Unfavorable);

        CuesAndKPIs.InsertData(
          DATABASE::"Activities Cue",
          ActivitiesCue.FieldNo("Overdue Sales Invoice Amount"),
          Style::None,
          10000,// Threshold 1
          Style::Ambiguous,
          100000,// Threshold 2
          Style::Unfavorable);

        CuesAndKPIs.InsertData(
          DATABASE::"Activities Cue",
          ActivitiesCue.FieldNo("Average Collection Days"),
          Style::Favorable,
          10,// Threshold 1
          Style::None,
          30,// Threshold 2
          Style::Unfavorable);

        CuesAndKPIs.InsertData(
          DATABASE::"Activities Cue",
          ActivitiesCue.FieldNo("Ongoing Sales Quotes"),
          Style::None,
          15,// Threshold 1
          Style::Ambiguous,
          30,// Threshold 2
          Style::Unfavorable);
    end;

    local procedure InsertDataForFinanceCue()
    var
        FinanceCue: Record "Finance Cue";
    begin
        // Finance Cue
        CuesAndKPIs.InsertData(
          DATABASE::"Finance Cue",
          FinanceCue.FieldNo("Overdue Purchase Documents"),
          Style::Favorable,
          0,// Threshold 1
          Style::None,
          1,// Threshold 2
          Style::Unfavorable);

        CuesAndKPIs.InsertData(
          DATABASE::"Finance Cue",
          FinanceCue.FieldNo("Purchase Documents Due Today"),
          Style::Favorable,
          0,// Threshold 1
          Style::None,
          1,// Threshold 2
          Style::Ambiguous);

        CuesAndKPIs.InsertData(
          DATABASE::"Finance Cue",
          FinanceCue.FieldNo("Purch. Invoices Due Next Week"),
          Style::Favorable,
          0,// Threshold 1
          Style::None,
          1,// Threshold 2
          Style::Ambiguous);

        CuesAndKPIs.InsertData(
          DATABASE::"Finance Cue",
          FinanceCue.FieldNo("Purchase Discounts Next Week"),
          Style::Favorable,
          0,// Threshold 1
          Style::Ambiguous,
          1,// Threshold 2
          Style::None);
    end;

    local procedure InsertDataForSalesCue()
    var
        SalesCue: Record "Sales Cue";
        SalesCueFields: array[5] of Integer;
        i: Integer;
    begin
        SalesCueFields[1] := SalesCue.FieldNo("Sales Quotes - Open");
        SalesCueFields[2] := SalesCue.FieldNo("Sales Orders - Open");
        SalesCueFields[3] := SalesCue.FieldNo("Ready to Ship");
        SalesCueFields[4] := SalesCue.FieldNo("Sales Return Orders - Open");
        SalesCueFields[5] := SalesCue.FieldNo("Sales Credit Memos - Open");

        for i := 1 to ArrayLen(SalesCueFields) do
            CuesAndKPIs.InsertData(
              DATABASE::"Sales Cue",
              SalesCueFields[i],
              Style::None,
              15,// Threshold 1
              Style::Ambiguous,
              20,// Threshold 2
              Style::Unfavorable);
        CuesAndKPIs.InsertData(
          DATABASE::"Sales Cue",
          SalesCue.FieldNo("Partially Shipped"),
          Style::Favorable,
          1,// Threshold 1
          Style::Ambiguous,
          20,// Threshold 2
          Style::Unfavorable);

        CuesAndKPIs.InsertData(
          DATABASE::"Sales Cue",
          SalesCue.FieldNo(Delayed),
          Style::Favorable,
          1,// Threshold 1
          Style::Ambiguous,
          20,// Threshold 2
          Style::Unfavorable);

        CuesAndKPIs.InsertData(
          DATABASE::"Sales Cue",
          SalesCue.FieldNo("Average Days Delayed"),
          Style::Favorable,
          3,// Threshold 1
          Style::None,
          7,// Threshold 2
          Style::Unfavorable);
    end;

    local procedure InsertDataForRlshpMgmtCue()
    var
        RelationshipMgmtCue: Record "Relationship Mgmt. Cue";
    begin
        CuesAndKPIs.InsertData(
          DATABASE::"Relationship Mgmt. Cue",
          RelationshipMgmtCue.FieldNo("Contacts - Duplicates"),
          Style::None,
          0,// Threshold 1
          Style::None,
          1,// Threshold 2
          Style::Unfavorable);
    end;
}
