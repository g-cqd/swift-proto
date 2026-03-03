//
//  MockGenerator+FunctionHelperDeclarations.swift
//  Proto
//
//  Created by Guillaume Coquard on 19.02.26.
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftSyntax

extension MockGenerator {
    static func synchronizationLockAccessor(for traits: FunctionTraits) -> String {
        traits.isStatic ? "Self._protoMockStaticLock" : "_protoMockLock"
    }

    static func synchronizedStorageName(for helperName: String, suffix: String) -> String {
        "_\(helperName)\(suffix)"
    }

    static func baseHelperDeclarations(
        for functionDecl: FunctionDeclSyntax,
        helperName: String,
        traits: FunctionTraits
    ) -> [DeclSyntax] {
        if traits.useSynchronizedState {
            return synchronizedBaseHelperDeclarations(
                for: functionDecl,
                helperName: helperName,
                traits: traits
            )
        }

        return unsynchronizedBaseHelperDeclarations(
            for: functionDecl,
            helperName: helperName,
            traits: traits
        )
    }

    static func returnValueHelperDeclarations(
        helperName: String,
        traits: FunctionTraits
    ) -> [DeclSyntax]? {
        guard let returnType = traits.returnType, traits.returnsValue else {
            return nil
        }

        let storageName =
            traits.useSynchronizedState
            ? synchronizedStorageName(for: helperName, suffix: "ReturnStub")
            : "\(helperName)ReturnStub"
        let returnStub = DeclSyntax(
            stringLiteral:
                "\(traits.helperPrivatePrefix)var \(storageName): ProtoMockReturnStub<\(returnType)> = .unset"
        )

        let setterSignature =
            "\(traits.helperAccessPrefix)\(traits.helperStaticPrefix)"
            + "func \(helperName)SetReturnValue(_ value: \(returnType))"
        let setterBody: String
        if traits.useSynchronizedState {
            let lockAccessor = synchronizationLockAccessor(for: traits)
            setterBody = """
                \(setterSignature) {
                        \(lockAccessor).withLock {
                                \(storageName) = .value(value)
                        }
                }
                """
        } else {
            setterBody = """
                \(setterSignature) {
                        \(storageName) = .value(value)
                }
                """
        }
        return [returnStub, DeclSyntax(stringLiteral: setterBody)]
    }

    private static func synchronizedBaseHelperDeclarations(
        for functionDecl: FunctionDeclSyntax,
        helperName: String,
        traits: FunctionTraits
    ) -> [DeclSyntax] {
        let lockAccessor = synchronizationLockAccessor(for: traits)
        let handlerType = functionHandlerType(functionDecl)
        var decls = [
            synchronizedCallCountDeclaration(
                helperName: helperName,
                traits: traits,
                lockAccessor: lockAccessor
            ),
            synchronizedHandlerDeclaration(
                helperName: helperName,
                handlerType: handlerType,
                traits: traits,
                lockAccessor: lockAccessor
            ),
        ]

        if let argumentType = traits.argumentType {
            decls.insert(
                synchronizedReceivedArgumentsDeclaration(
                    helperName: helperName,
                    argumentType: argumentType,
                    traits: traits,
                    lockAccessor: lockAccessor
                ),
                at: 1
            )
        }

        if traits.supportsErrorInjection {
            let thrownType = traits.throwsClause?.type?.trimmedDescription ?? "any Error"
            decls.append(
                synchronizedErrorDeclaration(
                    helperName: helperName,
                    thrownType: thrownType,
                    traits: traits,
                    lockAccessor: lockAccessor
                )
            )
        }

        return decls
    }

    private static func synchronizedCallCountDeclaration(
        helperName: String,
        traits: FunctionTraits,
        lockAccessor: String
    ) -> DeclSyntax {
        let storageName = synchronizedStorageName(for: helperName, suffix: "CallCount")
        let declaration = """
            \(traits.helperAccessPrefix)\(traits.helperStaticPrefix)var \(helperName)CallCount: Int {
                    \(lockAccessor).withLock { \(storageName) }
            }
                \(traits.helperPrivatePrefix)var \(storageName) = 0
            """
        return DeclSyntax(stringLiteral: declaration)
    }

    private static func synchronizedReceivedArgumentsDeclaration(
        helperName: String,
        argumentType: String,
        traits: FunctionTraits,
        lockAccessor: String
    ) -> DeclSyntax {
        let storageName = synchronizedStorageName(for: helperName, suffix: "ReceivedArguments")
        let declaration = """
            \(traits.helperAccessPrefix)\(traits.helperStaticPrefix)var \(helperName)ReceivedArguments: [\(argumentType)] {
                    \(lockAccessor).withLock { \(storageName) }
            }
                \(traits.helperPrivatePrefix)var \(storageName): [\(argumentType)] = []
            """
        return DeclSyntax(stringLiteral: declaration)
    }

    private static func synchronizedHandlerDeclaration(
        helperName: String,
        handlerType: String,
        traits: FunctionTraits,
        lockAccessor: String
    ) -> DeclSyntax {
        let storageName = synchronizedStorageName(for: helperName, suffix: "Handler")
        let declaration = """
            \(traits.helperAccessPrefix)\(traits.helperStaticPrefix)var \(helperName)Handler: (\(handlerType))? {
                    get { \(lockAccessor).withLock { \(storageName) } }
                    set { \(lockAccessor).withLock { \(storageName) = newValue } }
            }
                \(traits.helperPrivatePrefix)var \(storageName): (\(handlerType))?
            """
        return DeclSyntax(stringLiteral: declaration)
    }

    private static func synchronizedErrorDeclaration(
        helperName: String,
        thrownType: String,
        traits: FunctionTraits,
        lockAccessor: String
    ) -> DeclSyntax {
        let storageName = synchronizedStorageName(for: helperName, suffix: "Error")
        let declaration = """
            \(traits.helperAccessPrefix)\(traits.helperStaticPrefix)var \(helperName)Error: (\(thrownType))? {
                    get { \(lockAccessor).withLock { \(storageName) } }
                    set { \(lockAccessor).withLock { \(storageName) = newValue } }
            }
                \(traits.helperPrivatePrefix)var \(storageName): (\(thrownType))?
            """
        return DeclSyntax(stringLiteral: declaration)
    }

    private static func unsynchronizedBaseHelperDeclarations(
        for functionDecl: FunctionDeclSyntax,
        helperName: String,
        traits: FunctionTraits
    ) -> [DeclSyntax] {
        var decls = [DeclSyntax]()
        let callCountDecl =
            "\(traits.helperAccessPrefix)\(traits.helperStaticPrefix)private(set) var "
            + "\(helperName)CallCount = 0"
        decls.append(
            DeclSyntax(
                stringLiteral: callCountDecl
            )
        )

        if let argumentType = traits.argumentType {
            decls.append(
                DeclSyntax(
                    stringLiteral:
                        "\(traits.helperAccessPrefix)\(traits.helperStaticPrefix)private(set) var "
                        + "\(helperName)ReceivedArguments: [\(argumentType)] = []"
                )
            )
        }

        let handlerType = functionHandlerType(functionDecl)
        let handlerDecl =
            "\(traits.helperAccessPrefix)\(traits.helperStaticPrefix)var \(helperName)Handler: "
            + "(\(handlerType))?"
        decls.append(
            DeclSyntax(
                stringLiteral: handlerDecl
            )
        )

        if traits.supportsErrorInjection {
            let thrownType = traits.throwsClause?.type?.trimmedDescription ?? "any Error"
            let errorDecl =
                "\(traits.helperAccessPrefix)\(traits.helperStaticPrefix)var \(helperName)Error: "
                + "(\(thrownType))?"
            decls.append(
                DeclSyntax(
                    stringLiteral: errorDecl
                )
            )
        }

        return decls
    }
}
