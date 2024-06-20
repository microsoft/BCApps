// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Utilities;

using Microsoft.Utilities;

codeunit 1435 "Named Forward Link Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Insert(Name: Code[30]; Description: Text[250]; Link: Text[250]): Boolean
    var
        NamedForwardLink: Record "Named Forward Link";
    begin
        if Exists(Name) then
            exit(false);

        NamedForwardLink.Validate(Name, Name);
        NamedForwardLink.Validate(Description, Description);
        NamedForwardLink.Validate(Link, Link);
        exit(NamedForwardLink.Insert(true));
    end;

    procedure Modify(Name: Code[30]; Description: Text[250]; Link: Text[250]): Boolean
    var
        NamedForwardLink: Record "Named Forward Link";
    begin
        if not NamedForwardLink.Get(Name) then
            exit(false);

        NamedForwardLink.Validate(Description, Description);
        NamedForwardLink.Validate(Link, Link);
        exit(NamedForwardLink.Modify(true));
    end;

    procedure Exists(Name: Code[30]): Boolean
    var
        NamedForwardLink: Record "Named Forward Link";
    begin
        exit(NamedForwardLink.Get(Name))
    end;
}