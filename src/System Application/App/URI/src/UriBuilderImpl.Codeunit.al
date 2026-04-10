// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Utilities;

using System;

codeunit 3062 "Uri Builder Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Init(Uri: Text)
    begin
        UriBuilder := UriBuilder.UriBuilder(Uri);
    end;

    procedure SetScheme(Scheme: Text)
    begin
        UriBuilder.Scheme := Scheme;
    end;

    procedure GetScheme(): Text
    begin
        exit(UriBuilder.Scheme);
    end;

    procedure SetHost(Host: Text)
    begin
        UriBuilder.Host := Host;
    end;

    procedure GetHost(): Text
    begin
        exit(UriBuilder.Host);
    end;

    procedure SetPort(Port: Integer)
    begin
        UriBuilder.Port := Port;
    end;

    procedure GetPort(): Integer
    begin
        exit(UriBuilder.Port);
    end;

    procedure SetPath(Path: Text)
    begin
        UriBuilder.Path := Path;
    end;

    procedure GetPath(): Text
    begin
        exit(UriBuilder.Path);
    end;

    procedure SetQuery(Query: Text)
    begin
        UriBuilder.Query := Query;
    end;

    procedure GetQuery(): Text
    begin
        exit(UriBuilder.Query);
    end;

    procedure SetFragment(Fragment: Text)
    begin
        UriBuilder.Fragment := Fragment;
    end;

    procedure GetFragment(): Text
    begin
        exit(UriBuilder.Fragment);
    end;

    procedure GetUri(var Uri: Codeunit Uri)
    begin
        Uri.SetUri(UriBuilder.Uri);
    end;

    procedure AddQueryFlag(Flag: Text; DuplicateAction: Enum "Uri Query Duplicate Behaviour")
    begin
        AddQueryFlag(Flag, DuplicateAction, false);
    end;

    procedure AddQueryFlag(Flag: Text; DuplicateAction: Enum "Uri Query Duplicate Behaviour"; ShouldRemove: Boolean)
    var
        KeysWithValueList: Dictionary of [Text, List of [Text]];
        Flags: List of [Text];
        QueryString: Text;
    begin
        if Flag = '' then
            Error(FlagCannotBeEmptyErr);

        QueryString := GetQuery();
        ParseParametersAndFlags(QueryString, KeysWithValueList, Flags);
        ProcessNewFlag(Flags, Flag, DuplicateAction, ShouldRemove);
        QueryString := CreateNewQueryString(KeysWithValueList, Flags, false);

        SetQuery(QueryString);
    end;

    procedure AddQueryParameter(ParameterKey: Text; ParameterValue: Text; DuplicateAction: Enum "Uri Query Duplicate Behaviour")
    begin
        AddQueryParameterInternal(ParameterKey, ParameterValue, DuplicateAction, false, false);
    end;

    procedure AddODataQueryParameter(ParameterKey: Text; ParameterValue: Text)
    begin
        AddQueryParameterInternal(ParameterKey, ParameterValue, Enum::"Uri Query Duplicate Behaviour"::"Overwrite All Matching", true, false);
    end;

    procedure RemoveQueryParameter(ParameterKey: Text; ParameterValue: Text; DuplicateAction: Enum "Uri Query Duplicate Behaviour")
    begin
        AddQueryParameterInternal(ParameterKey, ParameterValue, DuplicateAction, false, true);
    end;

    local procedure AddQueryParameterInternal(ParameterKey: Text; ParameterValue: Text; DuplicateAction: Enum "Uri Query Duplicate Behaviour"; UseODataEncoding: Boolean; ShouldRemove: Boolean)
    var
        KeysWithValueList: Dictionary of [Text, List of [Text]];
        Flags: List of [Text];
        QueryString: Text;
    begin
        if ParameterKey = '' then
            Error(QueryParameterKeyCannotBeEmptyErr);

        QueryString := GetQuery();
        ParseParametersAndFlags(QueryString, KeysWithValueList, Flags);
        ProcessNewParameter(KeysWithValueList, ParameterKey, ParameterValue, DuplicateAction, ShouldRemove);
        QueryString := CreateNewQueryString(KeysWithValueList, Flags, UseODataEncoding);

        SetQuery(QueryString);
    end;

    local procedure ParseParametersAndFlags(QueryString: Text; var KeysWithValueList: Dictionary of [Text, List of [Text]]; var Flags: List of [Text])
    var
        ValueList: List of [Text];
        NameValueCollection: DotNet NameValueCollection;
        HttpUtility: DotNet HttpUtility;
        QueryKey: Text;
        QueryValue: Text;
        KeysCount: Integer;
        KeysIndex: Integer;
    begin
        // NOTE: ParseQueryString returns the value unencoded
        NameValueCollection := HttpUtility.ParseQueryString(QueryString);
        KeysCount := NameValueCollection.Count();

        for KeysIndex := 0 to KeysCount - 1 do
            // Flags (e.g. 'foo' and 'bar' in '?foo&bar') are all grouped under a null key.
            if IsNull(NameValueCollection.GetKey(KeysIndex)) then
                foreach QueryValue in NameValueCollection.GetValues(KeysIndex) do
                    Flags.Add(QueryValue) // No easy way to convert DotNet Array to AL List
            else begin
                QueryKey := NameValueCollection.GetKey(KeysIndex);
                Clear(ValueList);

                foreach QueryValue in NameValueCollection.GetValues(KeysIndex) do
                    ValueList.Add(QueryValue); // No easy way to convert DotNet Array to AL List

                KeysWithValueList.Add(QueryKey, ValueList);
            end;
    end;

    local procedure ProcessNewParameter(var KeysWithValueList: Dictionary of [Text, List of [Text]]; QueryKey: Text; QueryValue: Text; DuplicateAction: Enum "Uri Query Duplicate Behaviour"; ShouldRemove: Boolean)
    var
        Values: List of [Text];
    begin
        if not KeysWithValueList.ContainsKey(QueryKey) then begin
            if ShouldRemove then begin
                if DuplicateAction = DuplicateAction::"Throw Error" then
                    Error(ParameterNotFoundErr);
                exit;
            end;
            Values.Add(QueryValue);
            KeysWithValueList.Add(QueryKey, Values);
            exit;
        end;

        KeysWithValueList.Get(QueryKey, Values);

        if ShouldRemove then
            if Values.Contains(QueryValue) then begin
                Values.Remove(QueryValue); // Remove first-occurrence from List
                KeysWithValueList.Set(QueryKey, Values);
            end;

        case DuplicateAction of
            DuplicateAction::"Overwrite All Matching":
                begin
                    Clear(Values);
                    if not ShouldRemove then
                        Values.Add(QueryValue);
                    KeysWithValueList.Set(QueryKey, Values);
                end;
            DuplicateAction::Skip:
                ; // Do nothing
            DuplicateAction::"Keep All":
                begin
                    if not ShouldRemove then
                        Values.Add(QueryValue)
                    else
                        if Values.Contains(QueryValue) then
                            Values.Remove(QueryValue);
                    KeysWithValueList.Set(QueryKey, Values);
                end;
            DuplicateAction::"Throw Error":
                if not ShouldRemove then
                    Error(DuplicateParameterErr);
            else // In case the duplicate action is invalid, it's safer to error out than to have a malformed URL
                Error(DuplicateParameterErr);
        end;
    end;

    local procedure ProcessNewFlag(var Flags: List of [Text]; Flag: Text; DuplicateAction: Enum "Uri Query Duplicate Behaviour"; ShouldRemove: Boolean)
    var
        FlagsSizeBeforeRemove: Integer;
    begin
        if not Flags.Contains(Flag) then begin
            if not ShouldRemove then
                Flags.Add(Flag)
            else
                if DuplicateAction = DuplicateAction::"Throw Error" then
                    Error(FlagNotFoundErr);
            exit;
        end;

        if ShouldRemove then
            Flags.Remove(Flag); // Remove first occurence from List

        case DuplicateAction of
            DuplicateAction::Skip:
                ; // Do nothing
            DuplicateAction::"Overwrite All Matching":
                begin
                    // If multiple matching flags exist, we need to keep only one
                    repeat
                        FlagsSizeBeforeRemove := Flags.Count; // Doing this instead of "while flags.remove do;" protects against infinite loops
                        if Flags.Contains(Flag) then
                            if Flags.Remove(Flag) then;
                    until Flags.Count >= FlagsSizeBeforeRemove;

                    if not ShouldRemove then
                        Flags.Add(Flag);
                end;
            DuplicateAction::"Keep All":
                if not ShouldRemove then
                    Flags.Add(Flag);
            DuplicateAction::"Throw Error":
                if not ShouldRemove then
                    Error(DuplicateFlagErr);
            else // In case the duplicate action is invalid, it's safer to error out than to have a malformed URL
                Error(DuplicateFlagErr);
        end;
    end;

    procedure RemoveQueryParameters()
    begin
        SetQuery('');
    end;

    procedure GetQueryFlags(): List of [Text]
    var
        KeysWithValueList: Dictionary of [Text, List of [Text]];
        Flags: List of [Text];
        QueryString: Text;
    begin
        QueryString := GetQuery();
        ParseParametersAndFlags(QueryString, KeysWithValueList, Flags);
        exit(Flags);
    end;

    procedure GetQueryParameters(): Dictionary of [Text, List of [Text]]
    var
        KeysWithValueList: Dictionary of [Text, List of [Text]];
        Flags: List of [Text];
        QueryString: Text;
    begin
        QueryString := GetQuery();
        ParseParametersAndFlags(QueryString, KeysWithValueList, Flags);
        exit(KeysWithValueList);
    end;

    procedure GetQueryParameter(ParameterKey: Text): List of [Text]
    var
        KeysWithValueList: Dictionary of [Text, List of [Text]];
    begin
        KeysWithValueList := GetQueryParameters();
        if not KeysWithValueList.ContainsKey(ParameterKey) then
            exit;
        exit(KeysWithValueList.Get(ParameterKey));
    end;

    local procedure CreateNewQueryString(KeysWithValueList: Dictionary of [Text, List of [Text]]; Flags: List of [Text]; UseODataEncoding: Boolean) FinalQuery: Text
    var
        Uri: Codeunit Uri;
        CurrentKey: Text;
        CurrentValues: List of [Text];
        CurrentValue: Text;
    begin
        foreach CurrentKey in KeysWithValueList.Keys() do begin
            KeysWithValueList.Get(CurrentKey, CurrentValues);
            foreach CurrentValue in CurrentValues do
                FinalQuery += '&' + EncodeParameterKey(CurrentKey, UseODataEncoding) + '=' + Uri.EscapeDataString(CurrentValue);
        end;

        foreach CurrentKey in Flags do
            FinalQuery += '&' + Uri.EscapeDataString(CurrentKey);

        FinalQuery := DelChr(FinalQuery, '<', '&');
    end;

    local procedure EncodeParameterKey(ParameterKey: Text; UseODataEncoding: Boolean) EncodedParameterKey: Text
    var
        Uri: Codeunit Uri;
    begin
        // Uri.EscapeDataString converts all characters except for RFC 3986 unreserved characters (alphanumeric and "-", ".", "_", "~") to their hex
        // representation, as per: https://learn.microsoft.com/dotnet/api/system.uri.escapedatastring
        // "$" is reserved but has currently no meaning in query strings (i.e. it's safe to leave unencoded). Some servers don't recognize encoded
        // OData parameter keys (such as "%24filter"), hence this function.

        // Notice: even though parameters such as "$filter" and "$expand" will include "$" (and "(", ")", " ", ...) in the parameter value as well, we
        // assume the server will decode these correctly, and limit this special encoding only for the OData parameters keys.

        EncodedParameterKey := Uri.EscapeDataString(ParameterKey);

        if UseODataEncoding then
            EncodedParameterKey := EncodedParameterKey.Replace('%24', '$');
    end;

    var
        FlagCannotBeEmptyErr: Label 'The flag cannot be empty.';
        QueryParameterKeyCannotBeEmptyErr: Label 'The query parameter key cannot be empty.';
        DuplicateFlagErr: Label 'The provided query flag is already present in the URI.';
        DuplicateParameterErr: Label 'The provided query parameter is already present in the URI.';
        FlagNotFoundErr: Label 'The provided query flag is not present in the URI.';
        ParameterNotFoundErr: Label 'The provided query parameter is not present in the URI.';
        UriBuilder: DotNet UriBuilder;
}
