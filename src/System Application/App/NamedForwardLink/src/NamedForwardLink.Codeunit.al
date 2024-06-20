// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Utilities;

/// <summary>
/// This codeunit provides methods related to named forward links.
/// </summary>
codeunit 1434 "Named Forward Link"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Inserts a new named forward link if the name is not yet taken.
    /// </summary>
    /// <param name="Name">The name of the forward link.</param>
    /// <param name="Description">A description of the forward link.</param>
    /// <param name="Link">The URL of the forward link.</param>
    /// <returns>True if the record was inserted, false if the name exists or the record could not be inserted.</returns>
    procedure Insert(Name: Code[30]; Description: Text[250]; Link: Text[250]): Boolean
    var
        NamedForwardLinkImpl: Codeunit "Named Forward Link Impl.";
    begin
        exit(NamedForwardLinkImpl.Insert(Name, Description, Link));
    end;

    /// <summary>
    /// Modifies an existing named forward link if the name is not yet taken.
    /// </summary>
    /// <param name="Name">The name of the forward link.</param>
    /// <param name="Description">A description of the forward link.</param>
    /// <param name="Link">The URL of the forward link.</param>
    /// <returns>True if the record was modified, false if the name does not exists or the record could not be modified.</returns>
    procedure Modify(Name: Code[30]; Description: Text[250]; Link: Text[250]): Boolean
    var
        NamedForwardLinkImpl: Codeunit "Named Forward Link Impl.";
    begin
        exit(NamedForwardLinkImpl.Insert(Name, Description, Link));
    end;

    /// <summary>
    /// Use this method to check if a record with the given name exists.
    /// </summary>
    /// <param name="Name">The name to check.</param>
    /// <returns>True if a record with the given name exists, otherwise false.</returns>
    procedure Exists(Name: Code[30]): Boolean
    var
        NamedForwardLinkImpl: Codeunit "Named Forward Link Impl.";
    begin
        exit(NamedForwardLinkImpl.Exists(Name));
    end;

    /// <summary>
    /// Raise this event to let features add forward links.
    /// </summary>
    /// <remarks>
    /// This event is public so other features can raise the event.
    /// </remarks>
    [IntegrationEvent(false, false)]
    procedure OnLoadNamedForwardLinks();
    begin

    end;
}