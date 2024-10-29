namespace System.RestClient;

codeunit 2362 "Rest Client Exception Builder"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateException(RestClientException: Enum "Rest Client Exception"; ErrorMessage: Text) Exception: ErrorInfo
    begin
        Exception := CreateException(RestClientException, ErrorMessage, IsCollectingErrors());
    end;

    procedure CreateException(RestClientException: Enum "Rest Client Exception"; ErrorMessage: Text; Collectible: Boolean) Exception: ErrorInfo
    begin
        Exception.Message := ErrorMessage;
        Exception.CustomDimensions.Add('ExceptionCode', Format(RestClientException.AsInteger()));
        Exception.CustomDimensions.Add('ExceptionName', RestClientException.Names.Get(RestClientException.Ordinals.IndexOf(RestClientException.AsInteger())));
        Exception.Collectible := Collectible;
    end;
}