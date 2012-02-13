﻿namespace Boo.TinyAst

import System
import Boo.OMeta
import Boo.OMeta.Parser
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.Ast as AST
import Boo.Lang.PatternMatching

macro keywordsAndTokens:
"""
Generates rules for tokens and keywords for TinyAst.

From:
	keywordsAndTokens:
		eq = "="
		OR = "or"
	
it generates:

	EQ = Identifier(Name: "=" >> name) ^ makeToken("EQ", name)
	OR = Identifier(Name: "or" >> name) ^ makeToken("OR", name)
"""
	block as AST.Block = keywordsAndTokens.ParentNode
	for stmt in keywordsAndTokens.Body.Statements:
		match stmt:
			case ExpressionStatement(Expression: [| $name = $pattern |]):
				e = [| $(ReferenceExpression(Name: name.ToString().ToUpper())) = Identifier(Name: $pattern >> name) ^ makeToken($(StringLiteralExpression(name.ToString().ToUpper())) , name) |]
				e.LexicalInfo = stmt.LexicalInfo
				block.Add(e)

ometa TinyAstEvaluator:
	
	keywordsAndTokens:
		OR = "or"
		AND = "and"
		TRUE = "true"
		FALSE = "false"
		AS = "as"
		FOR = "for"
		IN = "in"
		assign = "="

	stmt = stmt_block | stmt_line
	stmt_line = stmt_expression
	stmt_expression = assignment
	stmt_block = stmt_for
	
		
	#expression = binary_expression | invocation | atom
	atom = reference | array_literal | boolean | literal
	
	literal = Literal() >> l  ^ (l as Literal).astLiteral
	
	array_literal = array_literal_multi
	
	array_literal_multi = Brackets(Kind: BracketType.Parenthesis, Form: Tuple(Forms: array_literal_multi_items >> tl)) ^ newArrayLiteral(null, tl)
	
	forArray[ruleName] = $(Apply(ruleName, (input.Head as Array)))
	
	array_literal_multi_items = (++assignment >> a, ~_) ^ a

	boolean = true_literal | false_literal
	
	true_literal = TRUE ^ [| true |]	
	false_literal = FALSE ^ [| false |]
	
	#binary_operator = ( Identifier(Name: "or") ^ Token("or", "or")) | ( Identifier(Name: "and") ^ Token("and","and"))
	binary_operator = OR | AND | ASSIGN
	
	binary_expression = Infix(Operator: binary_operator >> op, Left: assignment >> l, Right: assignment >> r) ^ newInfixExpression(op, l, r)
	
	reference = Identifier() >> r ^ ReferenceExpression(Name: (r as Identifier).Name)
	
	assignment = binary_expression | invocation | atom

	#declaration = ( ( Infix(Operator: AS, Left: Identifier(Name: _ >> name), Right: Identifier(Name: _ >> typeRef)) ) | Identifier(Name: _ >> name) ) ^ newDeclaration(Token(name, name), typeRef)
	
	declaration = Identifier(Name: _ >> name)  ^ newDeclaration(Token(name, name), null)		
	
	invocation = invocation_expression
	invocation_expression = Prefix(Operator: 
										reference >> target, 
									Operand: 
										Brackets(Kind: BracketType.Parenthesis, 
												 Form: invocation_arguments >> args
										)
									) ^ newInvocation(target, args, null)
	
	invocation_arguments = (Tuple(Forms: (++assignment >> a, ~_) ) ^ a) | (assignment >> b ^ [b])
	
	block = Block(Forms: (++(stmt >> s ^ ExpressionStatement(s as Expression)) >> a, ~_) ) ^ newBlock(null, null, a, null)
	
	stmt_for = Pair(Left:
						Prefix(Operator: FOR, Operand: Infix(Operator: IN, Left: declaration >> dl, Right: assignment >> e)),
					Right:
						block >> body) ^ newForStatement([dl], e, body, null, null)