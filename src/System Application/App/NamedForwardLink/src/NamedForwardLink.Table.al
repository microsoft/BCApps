// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Utilities; // TODO Can we change this to System.Utilities?

#if not CLEAN25
using System.Utilities;
#endif 

/// <summary>
/// This table stores links (URL's) which can be referenced elsewhere.
/// </summary>
table 1431 "Named Forward Link"
{
    Caption = 'Named Forward Link';
    DataClassification = CustomerContent;
    MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        /// <summary>
        /// The name of the link. The name should be meaningful and unique.
        /// </summary>
        field(1; Name; Code[30])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the name of the link. The name should be meaningful and unique.';
        }

        /// <summary>
        /// A description of the target of the link.
        /// </summary>
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the description of the target of the link.';
        }

        /// <summary>
        /// The URL of the link.
        /// </summary>
        field(3; Link; Text[250])
        {
            Caption = 'Link';
            DataClassification = SystemMetadata;
            ExtendedDatatype = URL;
            ToolTip = 'Specifies the URL of the link.';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

#if not CLEAN25
#pragma warning disable AL0432
    [Obsolete('This method is replaced by LoadNamedForwardLinks in Codeunit Named Forward Links.', '25.0')]
    procedure Load()
    var
        NamedForwardLink: Codeunit "Named Forward Link";
    begin
        OnLoad();
        NamedForwardLink.OnLoadNamedForwardLinks();
    end;

    [Obsolete('This event is replaced by OnLoadNamedForwardLinks in Codeunit Named Forward Links.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnLoad()
    begin
    end;
#pragma warning restore AL0432
#endif
}
