codeunit 101802 "Create FA Journal Setup"
{

    trigger OnRun()
    begin
        "FA Setup".Get();
        InsertData(
          '', "FA Setup"."Default Depr. Book", XQTYACC, XDEFAULT,
          XASSETS, XDEFAULT, XINSURANCE, XDEFAULT);

        InsertData(
          '', "FA Setup"."Release Depr. Book", XASSETS, XDEFAULT,
          XASSETS, XDEFAULT, XINSURANCE, XDEFAULT);
        InsertData(
          '', "FA Setup"."Quantitative Depr. Book", XQTYACC, XDEFAULT,
          XASSETS, XDEFAULT, '', '');

        InsertData(
          '', "FA Setup"."Future Depr. Book", XFUTEXP, XDEFAULT,
          XASSETS, XFUTEXP, '', '');
        InsertData(
          '', XUPGRADING, XASSETS, XDEFAULT,
          XASSETS, XDEFAULT, XINSURANCE, XDEFAULT);
        InsertData(
          '', XTAXACC, XASSETS, XDEFAULT,
          XASSETS, XDEFAULT, XINSURANCE, XDEFAULT);

        InsertData(
          '', XRENT, XASSETS, XDEFAULT,
          XASSETS, XDEFAULT, XINSURANCE, XDEFAULT);
        InsertData(
          '', XCLOSEDOWN, XASSETS, XDEFAULT,
          XASSETS, XDEFAULT, XINSURANCE, XDEFAULT);
    end;

    var
        "FA Setup": Record "FA Setup";
        "FA Journal Setup": Record "FA Journal Setup";
        XASSETS: Label 'ASSETS';
        XDEFAULT: Label 'DEFAULT';
        XINSURANCE: Label 'INSURANCE';
        XQTYACC: Label 'QTYACC';
        XFUTEXP: Label 'FUTEXP';
        XUPGRADING: Label 'UPGRADING';
        XTAXACC: Label 'TAXACC';
        XRENT: Label 'RENT';
        XCLOSEDOWN: Label 'CLOSEDOWN';

    procedure InsertData("User ID": Code[20]; "Depreciation Book Code": Code[10]; "FA Jnl. Template Name": Code[10]; "FA Jnl. Batch Name": Code[10]; "Gen. Jnl. Template Name": Code[10]; "Gen. Jnl. Batch Name": Code[10]; "Insurance Jnl. Template Name": Code[10]; "Insurance Jnl. Batch Name": Code[10])
    begin
        "FA Journal Setup"."User ID" := "User ID";
        "FA Journal Setup"."Depreciation Book Code" := "Depreciation Book Code";
        "FA Journal Setup"."FA Jnl. Template Name" := "FA Jnl. Template Name";
        "FA Journal Setup"."FA Jnl. Batch Name" := "FA Jnl. Batch Name";
        "FA Journal Setup"."Gen. Jnl. Template Name" := "Gen. Jnl. Template Name";
        "FA Journal Setup"."Gen. Jnl. Batch Name" := "Gen. Jnl. Batch Name";
        "FA Journal Setup"."Insurance Jnl. Template Name" := "Insurance Jnl. Template Name";
        "FA Journal Setup"."Insurance Jnl. Batch Name" := "Insurance Jnl. Batch Name";
        "FA Journal Setup".Insert(true);
    end;
}

