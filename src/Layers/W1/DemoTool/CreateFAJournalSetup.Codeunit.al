codeunit 101802 "Create FA Journal Setup"
{

    trigger OnRun()
    begin
        "FA Setup".Get();
        InsertData(
          '', "FA Setup"."Default Depr. Book", XASSETS, XDEFAULT,
          XASSETS, XDEFAULT, XINSURANCE, XDEFAULT);
    end;

    var
        "FA Setup": Record "FA Setup";
        "FA Journal Setup": Record "FA Journal Setup";
        XASSETS: Label 'ASSETS';
        XDEFAULT: Label 'DEFAULT';
        XINSURANCE: Label 'INSURANCE';

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

