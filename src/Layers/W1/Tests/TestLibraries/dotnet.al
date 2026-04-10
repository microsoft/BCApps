// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

dotnet
{
    assembly("Microsoft.Dynamics.Nav.PermissionTestHelper")
    {
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

#pragma warning disable AS0130
#pragma warning disable PTE0025
        type("Microsoft.Dynamics.Nav.Runtime.PermissionTestHelper"; "PermissionTestHelper")
        {
        }
#pragma warning restore AS0130
#pragma warning restore PTE0025
    }

    assembly(System.Security.Principal.Windows)
    {


        type("System.Security.Principal.WindowsIdentity"; "System.Security.Principal.WindowsIdentity")
        {
        }

        type("System.Security.Principal.SecurityIdentifier"; "System.Security.Principal.SecurityIdentifier")
        {
        }

    }

    assembly("netstandard")
    {
        type("System.Reflection.BindingFlags"; "System.Reflection.BindingFlags")
        {
        }

        type("System.UnauthorizedAccessException"; "System.UnauthorizedAccessException")
        {
        }
        type("System.Diagnostics.ProcessStartInfo"; "System.Diagnostics.ProcessStartInfo")
        {
        }
        type("System.Net.Http.HttpRequestMessage"; "HttpRequestMessage")
        {
        }
        type("System.Xml.XmlException"; "System.Xml.XmlException")
        {
        }

        type("System.Xml.Schema.XmlSchema"; "System.Xml.Schema.XmlSchema")
        {
        }

        type("System.Xml.Schema.ValidationEventHandler"; "System.Xml.Schema.ValidationEventHandler")
        {
        }
        type("System.Collections.ObjectModel.Collection`1"; "Collection1")
        {
        }
    }
}

