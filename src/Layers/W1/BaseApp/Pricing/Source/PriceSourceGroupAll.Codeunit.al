// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

codeunit 7012 "Price Source Group - All" implements "Price Source Group"
{
    procedure IsSourceTypeSupported(SourceType: Enum "Price Source Type"): Boolean;
    begin
        exit(true)
    end;

    procedure GetGroup() SourceGroup: Enum "Price Source Group";
    begin
        exit(SourceGroup::All);
    end;
}