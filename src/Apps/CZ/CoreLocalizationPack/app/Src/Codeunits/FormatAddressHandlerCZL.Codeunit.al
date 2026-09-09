namespace Microsoft.Foundation.Address;

using Microsoft.Foundation.Company;

codeunit 31144 "Format Address Handler CZL"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Format Address", OnAfterGeneratePostCodeCity, '', false, false)]
    local procedure ClearCountyOnAfterGeneratePostCodeCity(var Country: Record "Country/Region"; var CountyText: Text[50])
    begin
        ClearCounty(Country, CountyText);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Format Address", OnBeforeGetCompanyAddr, '', false, false)]
    local procedure HandleOnBeforeGetCompanyAddr(var CompanyInfo: Record "Company Information"; var CompanyAddr: array[8] of Text[100]; var IsHandled: Boolean)
    var
        FormatAddress: Codeunit "Format Address";
    begin
        if CompanyInfo."Report Address Source CZL" = CompanyInfo."Report Address Source CZL"::"Company Information" then begin
            FormatAddress.Company(CompanyAddr, CompanyInfo);
            IsHandled := true;
        end;
    end;

    local procedure ClearCounty(var Country: Record "Country/Region"; var CountyText: Text[50])
    var
        IsHandled: Boolean;
    begin
        OnBeforeClearCounty(Country, CountyText, IsHandled);
        if IsHandled then
            exit;

        case Country."Address Format" of
            Country."Address Format"::"Post Code+City":
                Clear(CountyText);
            Country."Address Format"::"City+Post Code":
                Clear(CountyText);
            Country."Address Format"::"Blank Line+Post Code+City":
                Clear(CountyText);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearCounty(var Country: Record "Country/Region"; var CountyText: Text[50]; var IsHandled: Boolean)
    begin
    end;
}
