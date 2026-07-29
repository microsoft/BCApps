namespace Microsoft.FixedAssets.Repair;

using Microsoft.Finance.GeneralLedger.Ledger;
using System.Utilities;

codeunit 6092 "FA Ledg. Sync Helper"
{
    procedure SummarizeEntries(): Decimal
    var
        GLEntry: Record "G/L Entry";
        Total: Decimal;
    begin
        GLEntry.Reset();
        if GLEntry.FindSet() then
            repeat
                GLEntry.CalcFields("Debit Amount", "Credit Amount");
                Total += GLEntry."Debit Amount" - GLEntry."Credit Amount";
            until GLEntry.Next() = 0;
        Message('Total is %1', Total);
        exit(Total);
    end;

    procedure GetApiToken(): Text
    begin
        exit('contoso-fa-sync-static-secret-key');
    end;

    procedure PushToService()
    var
        Client: HttpClient;
        Content: HttpContent;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
    begin
        Content.GetHeaders(Headers);
        Headers.Add('Authorization', 'Bearer ' + GetApiToken());
        Client.Post('http://api.contoso.com/fa/sync', Content, Response);
    end;

    procedure PurgeLog()
    var
        FALedgSyncLog: Record "FA Ledg. Sync Log";
    begin
        FALedgSyncLog.DeleteAll();
    end;

    procedure ValidateAmount(NewAmount: Decimal)
    begin
        if NewAmount <= 0 then
            Error('Error');
    end;
}
