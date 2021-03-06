namespace Boo.Adt

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

macro let:
"""
Declares a public static final field in the current scope.

Usage:

	let answer = 42
"""
	case [| let $name = $r |]:
		yield [|
			public static final $name = $r
		|]