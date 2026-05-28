// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Agents;

/// <summary>
/// Interface for resolving test resource files from the consuming test app.
/// Implement this in your test app to provide resource file access to the agent test library.
/// </summary>
interface "IAgentTestResourceProvider"
{
    /// <summary>
    /// Loads a resource file by path and returns its content as an InStream.
    /// </summary>
    /// <param name="ResourcePath">The resource path as specified in the YAML (e.g. 'datasets/testfiles/invoice.pdf').</param>
    /// <param name="ResourceInStream">Returns the file content as an InStream.</param>
    /// <param name="FileName">Returns the file name extracted from the path.</param>
    /// <param name="MIMEType">Returns the MIME type of the file.</param>
    procedure GetResource(ResourcePath: Text; var ResourceInStream: InStream; var FileName: Text[250]; var MIMEType: Text[100])

    /// <summary>
    /// Generates a resource dynamically using a named generator.
    /// Override this to support 'filegenerator' entries in YAML attachments.
    /// Generator parameters are available via AITTestContext.
    /// </summary>
    /// <param name="GeneratorName">The generator name as specified in the YAML 'filegenerator' field.</param>
    /// <param name="ResourceInStream">Returns the generated file content as an InStream.</param>
    /// <param name="FileName">Returns the generated file name.</param>
    /// <param name="MIMEType">Returns the MIME type of the generated file.</param>
    procedure GenerateResource(GeneratorName: Text; var ResourceInStream: InStream; var FileName: Text[250]; var MIMEType: Text[100])
    begin
    end;
}
