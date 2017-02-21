prompt plp$parser body
create or replace package body plp$parser is

/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/parser2.sql $
 *  $Author: vasiltsov $
 *  $Revision: 86610 $
 *  $Date:: 2015-11-23 13:36:43 #$
 */	
 
--# line 142 "plp.y"
/*
 *	_HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/trunk/IBS/PLP.Y 
 *  _Author: vasiltsov 
 *  _Revision: 86608 
 *  _Date:: 2015-11-23 13:25:09 #
 *	_HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/trunk/IBS/plp.l 
 *  _Author: vasiltsov 
 *  _Revision: 85998 
 *  _Date:: 2015-11-13 12:30:42 #
 */
	
	type integer_tbl_t is table of pls_integer index by binary_integer;
	type  YYSTYPE_tbl_t is table of YYSTYPE index by binary_integer;
	yyval YYSTYPE;
--# line 143 "PLP.Y"
--
/* internal procedures/functions declarations */
    procedure yyerror ( err_msg varchar2 );
    procedure yyoutput ( msg varchar2 );
	procedure dump_symbol ( sym IN YYSTYPE );
--
/* auxiliary variables */
	node		 plib.ir_node_t;
YYERRCODE constant pls_integer := 256;
--# line 2711 "PLP.Y"
YYNPROD constant pls_integer := 355;
yyexca integer_tbl_t;
YYLAST constant pls_integer := 3165;
yyact integer_tbl_t;
yypact integer_tbl_t;
yypgo integer_tbl_t;
yyr1 integer_tbl_t;
yyr2 integer_tbl_t;
yychk integer_tbl_t;
yydef integer_tbl_t;
--
/* $NoKeywords: $ */
	type tokens_tbl_t is table of pls_integer index by varchar2(16);
--
    procedure error_value;
	procedure lset;
	procedure lsetu;
    procedure extractToken;
    procedure extractModificator;
    flag    pls_integer;
    toks    tokens_tbl_t;
    fset    integer_tbl_t;
    idx pls_integer;
    put boolean;
    to_change_level boolean;
--
YYNEWLINE  constant varchar2(1) := chr(10);
vs integer_tbl_t;
v integer_tbl_t;
a integer_tbl_t;
f integer_tbl_t;
o integer_tbl_t;
s integer_tbl_t;
yytop  pls_integer := 642;
yybgin pls_integer := 1;
m integer_tbl_t;
e integer_tbl_t;
--
        YYLERR  constant pls_integer := 0;
        yylstate integer_tbl_t;                 -- index in list of prev states
        yyfnd    pls_integer;                -- index in vs
        yyprevious varchar2(1) := YYNEWLINE;    --
        --yydebug  boolean := FALSE;
        yymorfg  boolean := False;
        yytext   varchar2(32600);
--
YYMAXDEPTH constant pls_integer := 150;
YYFLAG constant pls_integer := -1000;
--
yydebug   boolean := False; /* True для отладки */
yynoerrs  boolean := False;
yychar    pls_integer := -1;    /* номер текущей лексемы */
yynerrs   pls_integer := 0;     /* число ошибок */
yyerrflag pls_integer := 0;     /* флаг восстановления после ошибок */
ABORT     exception;
--
procedure yyabort;
procedure yyerrok;
procedure yyclearin;
--
function yyparse return pls_integer is
	yys     integer_tbl_t;
	yyv     YYSTYPE_tbl_t;		/* стек для хранения значений */
        yyj     pls_integer;
        yym     pls_integer;
        yypvt   pls_integer;
        yystate pls_integer;
        yyps    pls_integer;
        yyn     pls_integer;
        yypv    pls_integer;
        yyxi    pls_integer;
        idx     pls_integer;    -- buffer for indexes
        idx1    pls_integer;    -- buffer for indexes
begin
	yystate   := 0;
	yychar    := -1;
	yynerrs   := 0;
	yyerrflag := 0;
	yyps := -1;
	yypv := -1;
	flag := 0; put := true;
--
	for ii in 0..YYMAXDEPTH loop
		yys(ii) := 0;
		yyv(ii) := yyval;
		--copy(yyval, yyv(ii));
	end loop;
	/*declare
		str varchar2(2000);
                idx pls_integer;
                sz  pls_integer := 0;
		gapped boolean := false;
                idx_prev pls_integer;
	begin
		yyoutput( 'yypvt=' || ns(to_char(yypvt)) );
		str := 'yyv: count=' || ns(to_char(yyv.count));
		str := str || ' first=' || ns(to_char(yyv.first));
		str := str || ' last=' || ns(to_char(yyv.last));
		idx := yyv.first;
		idx_prev := idx - 1;
		while idx is not null loop
			if (idx - idx_prev) != 1 then
				gapped := true;
			end if;
			sz := sz + nvl(length(yyv(idx).text), 0);
			sz := sz + nvl(length(yyv(idx).tag), 0);
			sz := sz + nvl(length(yyv(idx).decl_text), 0);
			sz := sz + nvl(length(yyv(idx).prog_text), 0);
			idx_prev := idx;
			idx := yyv.next(idx);
		end loop;
		str := str || ' size=' || ns(to_char(sz));
		if gapped then
			str := str || ' gapped';
		end if;
		yyoutput( str );
	end;*/
--
    <<yystack>>    /* занести состояние и значение в стек */
--    if( yydebug ) then yyoutput( 'state ' || to_char(yystate) || ', char ' || to_char(yychar) ); end if;
	yyps := yyps + 1;
    if yyps >= YYMAXDEPTH then
		yyerror( 'yacc stack overflow' );
		return 1;
	end if;
	yys(yyps) := yystate;
	yypv := yypv + 1;
	yyv(yypv) := yyval;
--
    <<yynewstate>>
	yyn := yypact(yystate);
	if yyn <= YYFLAG then
		goto yydefault; /* простое состояние */
	end if;
	if yychar < 0 then
                yychar := yylex;
/*        if yydebug then
		    if yychar > 32 and yychar < 256 then
	       		yyoutput( 'yylex = ' || chr(yychar) );
		    else
			yyoutput( 'yylex = ' || to_char(yychar) );
		    end if;
        end if;*/
		if yychar < 0 then
			yychar := 0;
		end if;
	end if;
	yyn := yyn + yychar;
	if yyn < 0 or yyn >= YYLAST then
		goto yydefault;
	end if;
	yyn := yyact(yyn);
	if yychk(yyn) = yychar then /* возможен сдвиг */
		yychar  := -1;
		yyval   := yylval;
		yystate := yyn;
		if yyerrflag > 0 then
			yyerrflag := yyerrflag - 1;
		end if;
		goto yystack;
	end if;
--
    <<yydefault>>  /* действие по умолчанию */
	yyn := yydef(yystate);
	if yyn = -2 then
		if yychar < 0 then
                        yychar := yylex;
/*			    if debug then
				if yychar > 32 and yychar < 256 then
			       	    yyoutput( 'yylex = ' || chr(yychar) );
				else
				    yyoutput( 'yylex = ' || to_char(yychar) );
				end if;
			    end if;*/
			if yychar < 0 then
				yychar := 0;
			end if;
		end if;
		/* просмотреть таблицу исключений */
		yyxi := 0;
		while (yyexca(yyxi) != (-1)) or (yyexca(yyxi+1) != yystate) loop
			yyxi := yyxi + 2;
		end loop;
		yyxi := yyxi + 2;
		while yyexca(yyxi) >= 0 loop
			if yyexca(yyxi) = yychar then
				exit;
			end if;
			yyxi := yyxi + 2;
		end loop;
		yyn := yyexca(yyxi+1);
		if yyn < 0 then
			return(0);   /* принято */
		end if;
	end if;
	if yyn = 0 then        /* ошибка */
		/* ошибка ... попытка продолжить разбор */
		if yyerrflag in ( 0, 1, 2 ) then
			if yyerrflag = 0 then     /* отметить новую ошибку */

				if not yynoerrs then
					yyerror( 'syntax error' );
				end if;
			<<yyerrlab>>
				yynerrs := yynerrs + 1;
			end if;
			/* неполностью восстановлено после ошибки, попробовать еще раз */
			yyerrflag := 3;
			/* поискать состояние где возможен сдвиг при "error" */
			while yyps >= 0 loop
				yyn := yypact(yys(yyps)) + YYERRCODE;
				if yyn >= 0 and
				   yyn < YYLAST and
				   yychk(yyact(yyn)) = YYERRCODE then

					/* имитировать сдвиг при "error" */
					yystate := yyact(yyn);
					goto yystack;
				end if;
				yyn := yypact(yys(yyps));
		 /* в текущем yyps нет сдвига для "error", поднять из стека */
/*                if yydebug then
				    if yyps <= 0 then
       					yyoutput( 'error recovery pops state ' || yys(yyps) ||', uncovers yys(' || to_char(yyps-1) || ')' );
				    else
					yyoutput( 'error recovery pops state ' || yys(yyps) ||', uncovers ' || yys(yyps-1) );
				    end if;
                end if;*/
				yyps := yyps - 1;
				yypv := yypv - 1;
			end loop;
		/* в стеке нет состояний со сдвигом для ошибки ... облом */
--
--		<<yyabort>>
			return 1;
--
		elsif yyerrflag = 3 then  /* нет возможности сдвига; прочитать лексему */
/*            if yydebug then
				yyoutput( 'error recovery discards char ' || yychar );
            end if;*/

			if yychar = 0 then
 --				goto yyabort; /* не пропускать EOF, конец */
				return 1;
			end if;
			yychar := -1;
			goto yynewstate;   /* попробовать еще раз в том же состоянии */
		end if;
	end if;
--
	/* свертка правила yyn */
/*    if yydebug then
		yyoutput( 'reduce ' || to_char(yyn) );
    end if;*/
	yyps := yyps - yyr2(yyn);
	yypvt := yypv;
	yypv := yypv - yyr2(yyn);
	yyval := yyv(yypv+1);
	--copy(yyv(yypv+1), yyval);
	yym := yyn;
	/* обратиться к таблице переходов чтобы узнать след. состояние */
	yyn := yyr1(yyn);
	yyj := yypgo(yyn) + yys(yyps) + 1;
	if yyj >= YYLAST then
		yystate := yyact(yypgo(yyn));
	else
		yystate := yyact(yyj);
		if yychk(yystate) != -yyn then
			yystate := yyact(yypgo(yyn));
		end if;
	end if;
--
	
if yym = 1 then
--# line 154 "PLP.Y"
					plib.set_node( node, NUMBER_, yyv(yypvt-0).line, yyv(yypvt-0).pos, yyv(yypvt-0).text, 'C', CONSTANT_ );
					yyval.node := plib.add2ir( node );
				
elsif yym = 2 then
--# line 159 "PLP.Y"
					plib.set_node( node, NUMBER_, yyv(yypvt-0).line, yyv(yypvt-0).pos, yyv(yypvt-0).text, 'C', CONSTANT_ );
					yyval.node := plib.add2ir( node );
				
elsif yym = 3 then
--# line 164 "PLP.Y"
					plib.set_node( node, STRING_, yyv(yypvt-0).line, yyv(yypvt-0).pos, yyv(yypvt-0).text, 'C', CONSTANT_ );
					yyval.node := plib.add2ir( node );
				
elsif yym = 4 then
--# line 169 "PLP.Y"
					plib.set_node( node, BOOLEAN_, yyv(yypvt-0).line, yyv(yypvt-0).pos, yyv(yypvt-0).text, 'C', CONSTANT_ );
					yyval.node := plib.add2ir( node );
				
elsif yym = 5 then
--# line 174 "PLP.Y"
                    plib.set_node( node, NULL_, yyv(yypvt-0).line, yyv(yypvt-0).pos, yyv(yypvt-0).text );
					yyval.node := plib.add2ir( node );
				
elsif yym = 11 then
--# line 191 "PLP.Y"
					yyval.text := 'is '||upper(yyv(yypvt-0).text);
				
elsif yym = 12 then
--# line 197 "PLP.Y"
					yyval.text := 'is not '||upper(yyv(yypvt-0).text);
				
elsif yym = 22 then
--# line 217 "PLP.Y"
					yyval.text := yyv(yypvt-1).text||' '||yyv(yypvt-0).text;
				
elsif yym = 28 then
--# line 233 "PLP.Y"
					yyval.text := yyv(yypvt-1).text||' '||yyv(yypvt-0).text;
				
elsif yym = 29 then
--# line 238 "PLP.Y"
					yyval.text := yyv(yypvt-1).text||' '||yyv(yypvt-0).text;
				
elsif yym = 31 then
--# line 248 "PLP.Y"
				plib.set_node( node, STRING_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL, CONCAT_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-2).node, yyv(yypvt-0).node );
			
elsif yym = 32 then
--# line 256 "PLP.Y"
				plib.set_node( node, NUMBER_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL, NUMLOW_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-2).node, yyv(yypvt-0).node );
			
elsif yym = 33 then
--# line 264 "PLP.Y"
				plib.set_node( node, NUMBER_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL, NUMHIGH_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-2).node, yyv(yypvt-0).node );
			
elsif yym = 34 then
--# line 272 "PLP.Y"
				plib.set_node( node, NUMBER_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL, POWER_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-2).node, yyv(yypvt-0).node );
			
elsif yym = 35 then
--# line 279 "PLP.Y"
                if yyv(yypvt-1).text in ('+','-') then idx:=NUMBER_; else idx := PRIOR_; end if;
                plib.set_node( node, idx, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL, PRIOR_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-0).node );
			
elsif yym = 36 then
--# line 288 "PLP.Y"
				plib.set_node( node, BOOLEAN_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL, LIKE_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-2).node, yyv(yypvt-0).node );
			
elsif yym = 37 then
--# line 298 "PLP.Y"
                plib.set_node( node, BOOLEAN_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-3).text, yyv(yypvt-1).text, LIKE_ );
                yyval.node := plib.add2ir( node, yyv(yypvt-4).node, yyv(yypvt-2).node, yyv(yypvt-0).node );
			
elsif yym = 38 then
--# line 306 "PLP.Y"
				plib.set_node( node, BOOLEAN_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL, RELATIONAL_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-2).node, yyv(yypvt-0).node );
			
elsif yym = 39 then
--# line 314 "PLP.Y"
				plib.set_node( node, BOOLEAN_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL, RELATIONAL_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-2).node, yyv(yypvt-0).node );
			
elsif yym = 40 then
--# line 325 "PLP.Y"
                plib.set_node( node, BOOLEAN_, yyv(yypvt-4).line, yyv(yypvt-4).pos, yyv(yypvt-4).text||' '||yyv(yypvt-3).text, NULL, IN_ );
                idx := plib.add2ir( node, yyv(yypvt-5).node );
                plib.add_child(idx, yyv(yypvt-1).node);
                yyval.node := idx;
			
elsif yym = 41 then
--# line 335 "PLP.Y"
				plib.set_node( node, BOOLEAN_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL, AND_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-2).node, yyv(yypvt-0).node );
			
elsif yym = 42 then
--# line 343 "PLP.Y"
				plib.set_node( node, BOOLEAN_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL, OR_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-2).node, yyv(yypvt-0).node );
			
elsif yym = 43 then
--# line 350 "PLP.Y"
				plib.set_node( node, BOOLEAN_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL, NOT_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-0).node );
			
elsif yym = 44 then
--# line 357 "PLP.Y"
				plib.set_node( node, BOOLEAN_, yyv(yypvt-0).line, yyv(yypvt-0).pos, yyv(yypvt-0).text, NULL, NULL_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-1).node );
			
elsif yym = 45 then
--# line 365 "PLP.Y"
				plib.set_node( node, BOOLEAN_, yyv(yypvt-0).line, yyv(yypvt-0).pos, 'is '||yyv(yypvt-0).text, NULL, COLLECTION_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-2).node );
			
elsif yym = 46 then
--# line 374 "PLP.Y"
				plib.set_node( node, BOOLEAN_, yyv(yypvt-0).line, yyv(yypvt-0).pos, 'is not '||yyv(yypvt-0).text, NULL, COLLECTION_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-3).node );
			
elsif yym = 47 then
--# line 384 "PLP.Y"
				plib.set_node( node, BOOLEAN_, yyv(yypvt-2).line, yyv(yypvt-2).pos, yyv(yypvt-2).text, NULL, COLLECTION_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-4).node, yyv(yypvt-0).node );
			
elsif yym = 48 then
--# line 395 "PLP.Y"
				plib.set_node( node, BOOLEAN_, yyv(yypvt-2).line, yyv(yypvt-2).pos, 'not '||yyv(yypvt-2).text, NULL, COLLECTION_ );
				yyval.node := plib.add2ir( node, yyv(yypvt-5).node, yyv(yypvt-0).node );
			
elsif yym = 49 then
--# line 405 "PLP.Y"
                plib.set_node( node, BOOLEAN_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-3).text, NULL, IN_ );
                idx := plib.add2ir( node, yyv(yypvt-4).node );
                plib.add_child(idx, yyv(yypvt-1).node);
                yyval.node := idx;
			
elsif yym = 50 then
--# line 416 "PLP.Y"
                plib.set_node( node, BOOLEAN_, yyv(yypvt-2).line, yyv(yypvt-2).pos, yyv(yypvt-3).text, NULL, EXISTS_ );
                yyval.node := plib.add2ir(node, yyv(yypvt-1).node);
			
elsif yym = 51 then
--# line 427 "PLP.Y"
                plib.set_node( node, BOOLEAN_, yyv(yypvt-4).line, yyv(yypvt-4).pos, yyv(yypvt-4).text||' '||yyv(yypvt-3).text, NULL, SELECT_ );
                yyval.node := plib.add2ir( node, yyv(yypvt-1).node, yyv(yypvt-5).node );
			
elsif yym = 52 then
--# line 437 "PLP.Y"
                plib.set_node( node, BOOLEAN_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-3).text, NULL, SELECT_ );
                yyval.node := plib.add2ir( node, yyv(yypvt-1).node, yyv(yypvt-4).node );
			
elsif yym = 53 then
--# line 451 "PLP.Y"
                plib.set_node( node, BOOLEAN_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-3).text, 'IN', SELECT_ );
                idx := plib.add2ir( node, yyv(yypvt-1).node );
                plib.add_child(idx, yyv(yypvt-7).node);
                plib.add_child(idx, yyv(yypvt-5).node);
                yyval.node := idx;
			
elsif yym = 54 then
--# line 461 "PLP.Y"
				yyval.node := yyv(yypvt-1).node;
				plib.get_node(yyval.node, node);
				if node.type != VAR_ and node.text1 is NULL then
					plib.set_text( yyval.node, NULL, 'P' );
				end if;
			
elsif yym = 56 then
--# line 472 "PLP.Y"
                plib.set_node( node, CURSOR_, yyv(yypvt-1).line, yyv(yypvt-1).pos, 'SELECT' );
                yyval.node := plib.add2ir( node, yyv(yypvt-1).node );
			
elsif yym = 57 then
--# line 480 "PLP.Y"
                plib.set_node( node, CURSOR_, yyv(yypvt-3).line, yyv(yypvt-3).pos,  'SELECT', yyv(yypvt-3).text );
                yyval.node := plib.add2ir( node, yyv(yypvt-1).node );
			
elsif yym = 58 then
--# line 488 "PLP.Y"
                plib.set_node( node, CURSOR_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
                yyval.node := plib.add2ir( node, yyv(yypvt-1).node );
			
elsif yym = 59 then
--# line 497 "PLP.Y"
				plib.set_node( node, UNION_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL);
				yyval.node := plib.add2ir( node, yyv(yypvt-3).node, yyv(yypvt-0).node );
			
elsif yym = 60 then
--# line 504 "PLP.Y"
                    yyval.text := yyv(yypvt-0).text;
                    yyval.node := ID_;
                
elsif yym = 61 then
--# line 509 "PLP.Y"
                    yyval.text := yyv(yypvt-0).text;
                    yyval.node := DBOBJECT_;
                
elsif yym = 63 then
--# line 519 "PLP.Y"
				yyval.node := yyv(yypvt-2).node;
				plib.add_sibling(yyv(yypvt-2).node, yyv(yypvt-0).node);
			
elsif yym = 65 then
--# line 529 "PLP.Y"
                plib.set_node(node, SETPAR_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-2).text);
                yyval.node := plib.add2ir(node,yyv(yypvt-0).node);
            
elsif yym = 67 then
--# line 539 "PLP.Y"
				yyval.node := yyv(yypvt-2).node;
				plib.add_sibling(yyv(yypvt-2).node, yyv(yypvt-0).node);
			
elsif yym = 68 then
--# line 548 "PLP.Y"
                plib.set_node(node, SETPAR_, yyv(yypvt-1).line, yyv(yypvt-1).pos);
                yyval.node := plib.add2ir(node,yyv(yypvt-1).node);
			
elsif yym = 69 then
--# line 556 "PLP.Y"
                plib.set_node(node, SETPAR_, yyv(yypvt-1).line, yyv(yypvt-1).pos);
                idx := plib.add2ir(node,yyv(yypvt-1).node);
                plib.add_sibling(yyv(yypvt-3).node, idx);
                yyval.node := yyv(yypvt-3).node;
			
elsif yym = 70 then
--# line 567 "PLP.Y"
				yyval.node := yyv(yypvt-1).node;
			
elsif yym = 71 then
--# line 572 "PLP.Y"
				yyval.node := NULL;
			
elsif yym = 72 then
--# line 577 "PLP.Y"
				yyval.node := NULL;
			
elsif yym = 73 then
--# line 581 "PLP.Y"
				yyval.node := yyv(yypvt-0).node;
			
elsif yym = 74 then
--# line 586 "PLP.Y"
                idx := yyv(yypvt-1).node;
                if idx is null then
				    yyval.node := yyv(yypvt-0).node;
                else
				    yyval.node := idx;
                    plib.add_sibling(idx, yyv(yypvt-0).node);
                end if;
			
elsif yym = 75 then
--# line 599 "PLP.Y"
				plib.set_node( node, yyv(yypvt-1).node, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text );
				idx := plib.add2ir( node );
				plib.add_child(idx, yyv(yypvt-0).node);
				plib.set_node( node, VAR_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
				yyval.node := plib.add2ir( node, idx );
			
elsif yym = 76 then
--# line 610 "PLP.Y"
                idx := yyv(yypvt-1).node;
                if idx=ID_ then idx:=RTL_; else idx:=DBCLASS_; end if;
				plib.set_node( node, idx, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, yyv(yypvt-1).text );
				idx := plib.add2ir( node );
				plib.add_child(idx, yyv(yypvt-0).node);
				plib.set_node( node, VAR_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
				yyval.node := plib.add2ir( node, idx );
			
elsif yym = 77 then
--# line 624 "PLP.Y"
				plib.set_node( node, DBCLASS_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-3).text, yyv(yypvt-3).text );
				idx1 := plib.add2ir( node );
				plib.set_node( node, DBOBJECT_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, yyv(yypvt-3).text );
				idx := plib.add2ir( node );
				plib.add_child(idx, yyv(yypvt-0).node);
				plib.set_node( node, VAR_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
				yyval.node := plib.add2ir( node, idx1, idx );
			
elsif yym = 78 then
--# line 638 "PLP.Y"
                plib.set_node( node, ID_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text );
				idx := plib.add2ir(node);
				plib.add_child(idx, yyv(yypvt-0).node);
				plib.add_child( yyv(yypvt-3).node, idx );
				yyval.node := yyv(yypvt-3).node;
			
elsif yym = 79 then
--# line 651 "PLP.Y"
                plib.set_node( node, OBJECT_REF_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-1).text,null,yyv(yypvt-3).node );
                idx := plib.add2ir(node);
                plib.add_child(idx, yyv(yypvt-2).node);
                plib.set_node( node, ID_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text );
				idx1 := plib.add2ir(node);
                plib.add_child(idx1, yyv(yypvt-0).node);
				plib.add_child( yyv(yypvt-4).node, idx );
				plib.add_child( yyv(yypvt-4).node, idx1 );
				yyval.node := yyv(yypvt-4).node;
			
elsif yym = 80 then
--# line 666 "PLP.Y"
                plib.set_node( node, MODIFIER_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL, yyv(yypvt-1).node );
                idx := plib.add2ir(node);
                plib.add_child( idx, yyv(yypvt-0).node );
				plib.add_child( yyv(yypvt-2).node, idx );
				yyval.node := yyv(yypvt-2).node;
			
elsif yym = 81 then
--# line 684 "PLP.Y"
                plib.set_node( node, WHERE_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
                idx := plib.add2ir(node, yyv(yypvt-3).node);
                plib.set_node( node, ORDER_, yyv(yypvt-2).line, yyv(yypvt-2).pos, plib.collect_text(yyv(yypvt-2).node, FALSE, FALSE, FALSE) );
                idx1:= plib.add2ir(node);
                plib.add_child(idx1,yyv(yypvt-2).node);
                plib.set_node( node, LOCATE_, yyv(yypvt-8).line, yyv(yypvt-8).pos, yyv(yypvt-5).text, null,yyv(yypvt-4).node+yyv(yypvt-1).node );
                idx := plib.add2ir( node, idx, idx1 );
                plib.set_node( node, MODIFIER_, yyv(yypvt-8).line, yyv(yypvt-8).pos, yyv(yypvt-8).text, yyv(yypvt-6).text, LOCATE_ );
                idx := plib.add2ir(node,idx);
                plib.add_child(yyv(yypvt-9).node, idx );
				yyval.node := yyv(yypvt-9).node;
            
elsif yym = 82 then
--# line 700 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
				yyval.node := OBJ_ID_;
			
elsif yym = 83 then
--# line 705 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
				yyval.node := OBJ_COLLECTION_;
			
elsif yym = 84 then
--# line 710 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
				yyval.node := OBJ_STATE_;
			
elsif yym = 85 then
--# line 715 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
				yyval.node := OBJ_CLASS_;
			
elsif yym = 86 then
--# line 720 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
				yyval.node := OBJ_PARENT_;
			
elsif yym = 87 then
--# line 725 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
                yyval.node := OBJ_CLASS_PARENT_;
			
elsif yym = 88 then
--# line 730 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
                yyval.node := OBJ_CLASS_ENTITY_;
			
elsif yym = 89 then
--# line 735 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
                yyval.node := ID_;
			
elsif yym = 90 then
--# line 740 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
                yyval.node := OBJ_TYPE_;
			
elsif yym = 91 then
--# line 745 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
                yyval.node := OBJ_INIT_;
			
elsif yym = 92 then
--# line 750 "PLP.Y"
                yyval.text := yyv(yypvt-0).text;
                yyval.node := DBCLASS_;
			
elsif yym = 93 then
--# line 755 "PLP.Y"
                yyval.text := yyv(yypvt-0).text;
                yyval.node := RTL_;
			
elsif yym = 94 then
--# line 760 "PLP.Y"
                yyval.text := yyv(yypvt-0).text;
                yyval.node := SOS_;
			
elsif yym = 95 then
--# line 765 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
                yyval.node := INSERT_;
			
elsif yym = 96 then
--# line 770 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
                yyval.node := ROWID_;
			
elsif yym = 97 then
--# line 775 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
                yyval.node := DELETE_;
			
elsif yym = 98 then
--# line 780 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
                yyval.node := ATTR_;
			
elsif yym = 99 then
--# line 785 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
                yyval.node := REF_;
			
elsif yym = 100 then
--# line 790 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
                yyval.node := COLLECTION_;
			
elsif yym = 101 then
--# line 796 "PLP.Y"
				yyval.text := yyv(yypvt-0).text;
                yyval.node := yyv(yypvt-0).node;
                if yyval.node < 4000 then
				    yyval.node := yyval.node + 4000;
                end if;

			
elsif yym = 102 then
--# line 807 "PLP.Y"
					plib.set_node( node, STRING_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
					yyval.node := plib.add2ir(node);
				
elsif yym = 103 then
--# line 815 "PLP.Y"
					plib.set_node( node, STRING_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-1).text );
					yyval.node := plib.add2ir(node);
				
elsif yym = 104 then
--# line 824 "PLP.Y"
					plib.set_node( node, STRING_, yyv(yypvt-4).line, yyv(yypvt-4).pos, yyv(yypvt-2).text, yyv(yypvt-1).text );
					yyval.node := plib.add2ir(node);
				
elsif yym = 105 then
--# line 830 "PLP.Y"
					plib.set_node( node, NSTRING_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
					yyval.node := plib.add2ir(node);
				
elsif yym = 106 then
--# line 838 "PLP.Y"
					plib.set_node( node, NSTRING_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-1).text );
					yyval.node := plib.add2ir(node);
				
elsif yym = 107 then
--# line 843 "PLP.Y"
					plib.set_node( node, INTEGER_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
					yyval.node := plib.add2ir(node);
				
elsif yym = 108 then
--# line 850 "PLP.Y"
					plib.set_node( node, NUMBER_, yyv(yypvt-0).line, yyv(yypvt-0).pos, NULL, NULL );
					yyval.node := plib.add2ir(node);
				
elsif yym = 109 then
--# line 858 "PLP.Y"
					plib.set_node( node, NUMBER_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-1).text, NULL );
					yyval.node := plib.add2ir(node);
				
elsif yym = 110 then
--# line 868 "PLP.Y"
					plib.set_node( node, NUMBER_, yyv(yypvt-5).line, yyv(yypvt-5).pos, yyv(yypvt-3).text, yyv(yypvt-1).text );
					yyval.node := plib.add2ir(node);
				
elsif yym = 111 then
--# line 879 "PLP.Y"
					plib.set_node( node, NUMBER_, yyv(yypvt-6).line, yyv(yypvt-6).pos, yyv(yypvt-4).text, '-'||yyv(yypvt-1).text );
					yyval.node := plib.add2ir(node);
				
elsif yym = 112 then
--# line 884 "PLP.Y"
					plib.set_node( node, DATE_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
					yyval.node := plib.add2ir(node);
				
elsif yym = 113 then
--# line 889 "PLP.Y"
					plib.set_node( node, BOOLEAN_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
					yyval.node := plib.add2ir(node);
				
elsif yym = 114 then
--# line 894 "PLP.Y"
                    plib.set_node( node, EXCEPTION_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
					yyval.node := plib.add2ir(node);
				
elsif yym = 115 then
--# line 899 "PLP.Y"
                    plib.set_node( node, RAW_, yyv(yypvt-0).line, yyv(yypvt-0).pos, 'RAW', constant.RAW_PREC );
					yyval.node := plib.add2ir(node);
				
elsif yym = 116 then
--# line 907 "PLP.Y"
                    plib.set_node( node, RAW_, yyv(yypvt-3).line, yyv(yypvt-3).pos, 'RAW', yyv(yypvt-1).text );
					yyval.node := plib.add2ir(node);
				
elsif yym = 117 then
--# line 912 "PLP.Y"
                    plib.set_node( node, RAW_, yyv(yypvt-0).line, yyv(yypvt-0).pos, 'LONG' );
					yyval.node := plib.add2ir(node);
				
elsif yym = 118 then
--# line 918 "PLP.Y"
                    plib.set_node( node, RAW_, yyv(yypvt-1).line, yyv(yypvt-1).pos, 'LONG RAW' );
					yyval.node := plib.add2ir(node);
				
elsif yym = 119 then
--# line 923 "PLP.Y"
                    plib.set_node( node, RAW_, yyv(yypvt-0).line, yyv(yypvt-0).pos, upper(yyv(yypvt-0).text) );
					yyval.node := plib.add2ir(node);
				
elsif yym = 120 then
--# line 928 "PLP.Y"
					plib.set_node(node,TIMESTAMP_,yyv(yypvt-0).line,yyv(yypvt-0).pos);
					yyval.node := plib.add2ir(node);
				
elsif yym = 121 then
--# line 936 "PLP.Y"
					plib.set_node(node,TIMESTAMP_,yyv(yypvt-3).line,yyv(yypvt-3).pos,yyv(yypvt-1).text);
					yyval.node := plib.add2ir(node);
				
elsif yym = 122 then
--# line 946 "PLP.Y"
					plib.set_node(node,TIMESTAMP_,yyv(yypvt-5).line,yyv(yypvt-5).pos,yyv(yypvt-3).text,yyv(yypvt-1).text);
					yyval.node := plib.add2ir(node);
				
elsif yym = 123 then
--# line 951 "PLP.Y"
					plib.set_node(node,INTERVAL_,yyv(yypvt-0).line,yyv(yypvt-0).pos);
					yyval.node := plib.add2ir(node);
				
elsif yym = 124 then
--# line 959 "PLP.Y"
					plib.set_node(node,INTERVAL_,yyv(yypvt-3).line,yyv(yypvt-3).pos,yyv(yypvt-1).text);
					yyval.node := plib.add2ir(node);
				
elsif yym = 125 then
--# line 969 "PLP.Y"
					plib.set_node(node,INTERVAL_,yyv(yypvt-5).line,yyv(yypvt-5).pos,yyv(yypvt-3).text,yyv(yypvt-1).text);
					yyval.node := plib.add2ir(node);
				
elsif yym = 126 then
--# line 977 "PLP.Y"
					plib.set_node( node, REF_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-0).text/*, NULL, ID_*/ );
					yyval.node := plib.add2ir( node );
				
elsif yym = 127 then
--# line 982 "PLP.Y"
					yyval.node := yyv(yypvt-0).node;
                
elsif yym = 131 then
--# line 993 "PLP.Y"
                yyval.node := yyv(yypvt-2).node;
            
elsif yym = 132 then
--# line 999 "PLP.Y"
                yyval.node := yyv(yypvt-2).node;
            
elsif yym = 133 then
--# line 1005 "PLP.Y"
				yyval.text := NULL;
			
elsif yym = 137 then
--# line 1013 "PLP.Y"
                yyval.text := yyv(yypvt-1).text||' '||yyv(yypvt-0).text||' NOCOPY';
			
elsif yym = 138 then
--# line 1019 "PLP.Y"
				yyval.node := NULL;
			
elsif yym = 139 then
--# line 1024 "PLP.Y"
                yyval.node := yyv(yypvt-0).node;
            
elsif yym = 140 then
--# line 1029 "PLP.Y"
                yyval.node := yyv(yypvt-0).node;
            
elsif yym = 141 then
--# line 1038 "PLP.Y"
			plib.set_node( node, ID_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-3).text, yyv(yypvt-2).text );
            yyval.node := plib.add2ir(node, yyv(yypvt-1).node, yyv(yypvt-0).node);
		
elsif yym = 142 then
--# line 1045 "PLP.Y"
					yyval.node := yyv(yypvt-0).node;
				
elsif yym = 143 then
--# line 1051 "PLP.Y"
					yyval.node := yyv(yypvt-2).node;
					plib.add_sibling(yyv(yypvt-2).node, yyv(yypvt-0).node);
				
elsif yym = 144 then
--# line 1057 "PLP.Y"
					yyerrok;
					yyclearin;
					plib.set_node( node, INVALID_ );
					yyval.node := plib.add2ir( node );
				
elsif yym = 145 then
--# line 1065 "PLP.Y"
				plib.set_node( node, DECLARE_, NULL, NULL);
				yyval.node := plib.add2ir(node);
			
elsif yym = 146 then
--# line 1072 "PLP.Y"
				plib.set_node( node, DECLARE_, yyv(yypvt-2).line, yyv(yypvt-2).pos);
				yyval.node := plib.add2ir(node);
				plib.add_child( yyval.node, yyv(yypvt-1).node );
			
elsif yym = 147 then
--# line 1083 "PLP.Y"
					plib.set_node( node, TYPE_, yyv(yypvt-3).line, yyv(yypvt-3).pos, NULL, NULL, RECORD_ );
					yyval.node := plib.add2ir(node);
					plib.add_child(yyval.node, yyv(yypvt-1).node);
				
elsif yym = 148 then
--# line 1092 "PLP.Y"
					plib.set_node( node, TYPE_, yyv(yypvt-3).line, yyv(yypvt-3).pos, NULL, NULL, TABLE_ );
                    idx := plib.add2ir(node,yyv(yypvt-1).node);
                    plib.add_child(idx,yyv(yypvt-0).node);
                    yyval.node := idx;
				
elsif yym = 149 then
--# line 1104 "PLP.Y"
    				plib.set_node( node, INTEGER_, yyv(yypvt-5).line, yyv(yypvt-5).pos );
	    			idx := plib.add2ir(node);
    				plib.set_node( node, BOOLEAN_, yyv(yypvt-5).line, yyv(yypvt-5).pos );
    				idx1:= plib.add2ir(node);
					plib.set_node( node, TYPE_, yyv(yypvt-5).line, yyv(yypvt-5).pos, NULL, yyv(yypvt-3).text, TABLE_ );
                    idx := plib.add2ir(node,yyv(yypvt-0).node,idx,idx1);
    				plib.set_node( node, INTEGER_, yyv(yypvt-5).line, yyv(yypvt-5).pos );
	    			idx1 := plib.add2ir(node);
                    plib.add_child(idx,idx1);
                    yyval.node := idx;
				
elsif yym = 150 then
--# line 1118 "PLP.Y"
                    plib.set_node( node, TYPE_, yyv(yypvt-1).line, yyv(yypvt-1).pos, NULL, NULL, CURSOR_ );
                    idx:= plib.add2ir(NULL_,null,null,null);
                    yyval.node := plib.add2ir(node,idx);
				
elsif yym = 151 then
--# line 1127 "PLP.Y"
                    plib.set_node( node, TYPE_, yyv(yypvt-3).line, yyv(yypvt-3).pos, NULL, NULL, CURSOR_ );
                    yyval.node := plib.add2ir(node, yyv(yypvt-0).node);
				
elsif yym = 152 then
--# line 1132 "PLP.Y"
					plib.set_node( node, TYPE_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
					yyval.node := plib.add2ir(node, yyv(yypvt-0).node);
				
elsif yym = 153 then
--# line 1137 "PLP.Y"
                    plib.set_node( node, TYPE_, yyv(yypvt-0).line, yyv(yypvt-0).pos, NULL, NULL, SELECT_ );
                    yyval.node := plib.add2ir(node,yyv(yypvt-0).node);
				
elsif yym = 154 then
--# line 1148 "PLP.Y"
					plib.set_text(yyv(yypvt-1).node, yyv(yypvt-3).text);
					yyval.node := yyv(yypvt-1).node;
                    plib.process_declare_level();
				
elsif yym = 156 then
--# line 1158 "PLP.Y"
					yyval.node := yyv(yypvt-1).node;
					idx := yyval.node;
					plib.process_public_modifier(idx);
				
elsif yym = 158 then
--# line 1167 "PLP.Y"
					yyval.node := yyv(yypvt-0).node;
					idx := yyval.node;
					plib.process_public_modifier(idx);
				
elsif yym = 161 then
--# line 1178 "PLP.Y"
					yyval.node := yyv(yypvt-0).node;
					idx := yyval.node;
					plib.process_public_modifier(idx);
				
elsif yym = 163 then
--# line 1187 "PLP.Y"
					plib.set_node( node, TEXT_, yyv(yypvt-0).line, yyv(yypvt-0).pos, yyv(yypvt-0).text );
					yyval.node := plib.add2ir(node);
				
elsif yym = 169 then
--# line 1199 "PLP.Y"
                plib.set_node( node, LOOP_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
                yyval.node := plib.add2ir( node, yyv(yypvt-0).node );
            
elsif yym = 170 then
--# line 1205 "PLP.Y"
                plib.set_node( node, NULL_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
                yyval.node := plib.add2ir(node);
            
elsif yym = 171 then
--# line 1212 "PLP.Y"
                plib.set_node( node, GOTO_, yyv(yypvt-2).line, yyv(yypvt-2).pos, yyv(yypvt-1).text );
                yyval.node := plib.add2ir(node);
            
elsif yym = 172 then
--# line 1218 "PLP.Y"
                plib.set_node( node, EXIT_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
                yyval.node := plib.add2ir(node);
            
elsif yym = 173 then
--# line 1225 "PLP.Y"
                plib.set_node( node, EXIT_, yyv(yypvt-2).line, yyv(yypvt-2).pos, yyv(yypvt-1).text );
                yyval.node := plib.add2ir(node);
            
elsif yym = 174 then
--# line 1233 "PLP.Y"
                plib.set_node( node, EXIT_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
                yyval.node := plib.add2ir(node, yyv(yypvt-1).node);
            
elsif yym = 175 then
--# line 1242 "PLP.Y"
                plib.set_node( node, EXIT_, yyv(yypvt-4).line, yyv(yypvt-4).pos, yyv(yypvt-3).text );
                yyval.node := plib.add2ir(node, yyv(yypvt-1).node);
            
elsif yym = 183 then
--# line 1258 "PLP.Y"
                plib.set_node( node, INTO_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
                idx := plib.add2ir( node );
                plib.add_child(idx,yyv(yypvt-1).node);
                plib.add_child(yyv(yypvt-3).node,idx,false);
                yyval.node := yyv(yypvt-3).node;
            
elsif yym = 185 then
--# line 1269 "PLP.Y"
                plib.set_node( node, LABEL_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text );
                yyval.node := plib.add2ir( node );
            
elsif yym = 186 then
--# line 1276 "PLP.Y"
				plib.set_node( node, SAVEPOINT_, yyv(yypvt-2).line, yyv(yypvt-2).pos, yyv(yypvt-1).text );
				yyval.node := plib.add2ir( node );
			
elsif yym = 187 then
--# line 1282 "PLP.Y"
				plib.set_node( node, ROLLBACK_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
				yyval.node := plib.add2ir( node );
			
elsif yym = 188 then
--# line 1290 "PLP.Y"
				plib.set_node( node, ROLLBACK_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-1).text );
				yyval.node := plib.add2ir( node );
			
elsif yym = 189 then
--# line 1296 "PLP.Y"
				plib.set_node( node, COMMIT_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
				yyval.node := plib.add2ir( node );
			
elsif yym = 190 then
--# line 1302 "PLP.Y"
				plib.set_node( node, CONTINUE_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
				yyval.node := plib.add2ir( node );
			
elsif yym = 191 then
--# line 1307 "PLP.Y"
				plib.set_node( node, TEXT_, yyv(yypvt-0).line, yyv(yypvt-0).pos, yyv(yypvt-0).text );
				yyval.node := plib.add2ir( node );
            
elsif yym = 192 then
--# line 1313 "PLP.Y"
                yyval.node := yyv(yypvt-0).node;
            
elsif yym = 193 then
--# line 1322 "PLP.Y"
                plib.set_node( node, ID_, yyv(yypvt-4).line, yyv(yypvt-4).pos, yyv(yypvt-4).text );
                idx := plib.add2ir( node );
                plib.add_child(idx,yyv(yypvt-2).node);
                plib.add_child(yyv(yypvt-5).node,idx);
                yyval.node := yyv(yypvt-5).node;
            
elsif yym = 196 then
--# line 1333 "PLP.Y"
				yyerrok;
				yyclearin;
				plib.set_node( node, INVALID_ );
				yyval.node := plib.add2ir( node );
			
elsif yym = 197 then
--# line 1345 "PLP.Y"
							plib.set_node( node, ASSIGN_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
                            yyval.node := plib.add2ir( node, yyv(yypvt-3).node, yyv(yypvt-1).node );
						
elsif yym = 198 then
--# line 1352 "PLP.Y"
                            plib.add_child(yyv(yypvt-0).node,yyv(yypvt-2).node);
                            yyval.node := yyv(yypvt-0).node;
                        
elsif yym = 199 then
--# line 1362 "PLP.Y"
						plib.set_node( node, PRAGMA_, yyv(yypvt-2).line, yyv(yypvt-2).pos, yyv(yypvt-2).text );
						yyval.node := plib.add2ir( node );
						plib.add_child( yyval.node, yyv(yypvt-1).node);
						if yyv(yypvt-2).text = plib.ORIGIN_PRAGMA then
                            idx:= -yyval.node;
                            plib.use_pragma(idx);
                        elsif yyv(yypvt-2).text in (plib.DEFINE_PRAGMA,plib.IF_DEF_PRAGMA,plib.END_IF_PRAGMA) then
                            idx := yyval.node;
                            plib.use_pragma(idx);
                        elsif yyv(yypvt-2).text in (plib.MACRO_PRAGMA,plib.INCLUDE_PRAGMA) then
                            idx := yyval.node;
                            plib.use_pragma(idx);
                            yyval.node := NULL;
                        elsif yyv(yypvt-2).text in (plib.RESTRICT_REFERENCES_PRAGMA, plib.EXCEPTION_INIT_PRAGMA, plib.SERIALLY_REUSABLE_PRAGMA) then
                            idx := yyval.node;
                            plib.process_spec_pragma_for_public(idx);
						end if;
					
elsif yym = 200 then
--# line 1387 "PLP.Y"
						plib.set_node( node, PRAGMA_, yyv(yypvt-2).line, yyv(yypvt-2).pos, yyv(yypvt-2).text );
						yyval.node := plib.add2ir( node );
						plib.add_child( yyval.node, yyv(yypvt-1).node);
						idx := yyval.node;
						plib.process_public_modifier(idx);
						if yyv(yypvt-2).text in (plib.MACRO_PRAGMA,plib.INCLUDE_PRAGMA) then
						  yyval.node := NULL;
						end if;
					
elsif yym = 201 then
--# line 1403 "PLP.Y"
				plib.set_node( node, ELSIF_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
				yyval.node := plib.add2ir( node, yyv(yypvt-2).node, yyv(yypvt-0).node );
			
elsif yym = 202 then
--# line 1409 "PLP.Y"
				plib.set_node( node, ELSE_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
				yyval.node := plib.add2ir( node, yyv(yypvt-0).node );
			
elsif yym = 203 then
--# line 1416 "PLP.Y"
				yyval.node :=  yyv(yypvt-0).node;
			
elsif yym = 204 then
--# line 1421 "PLP.Y"
				plib.add_sibling(yyv(yypvt-1).node, yyv(yypvt-0).node);
				yyval.node := yyv(yypvt-1).node;
			
elsif yym = 205 then
--# line 1435 "PLP.Y"
					plib.set_node( node, ELSIF_, yyv(yypvt-7).line, yyv(yypvt-7).pos );
					idx := plib.add2ir( node, yyv(yypvt-6).node, yyv(yypvt-4).node );
					plib.set_node( node, IF_, yyv(yypvt-7).line, yyv(yypvt-7).pos );
					yyval.node := plib.add2ir( node, idx );
					plib.add_sibling(idx, yyv(yypvt-3).node);
				
elsif yym = 206 then
--# line 1449 "PLP.Y"
					plib.set_node( node, ELSIF_, yyv(yypvt-6).line, yyv(yypvt-6).pos );
					idx := plib.add2ir( node, yyv(yypvt-5).node, yyv(yypvt-3).node );
					plib.set_node( node, IF_, yyv(yypvt-6).line, yyv(yypvt-6).pos );
					yyval.node := plib.add2ir( node, idx );
				
elsif yym = 207 then
--# line 1462 "PLP.Y"
                plib.set_node( node, IN_, yyv(yypvt-4).line, yyv(yypvt-4).pos );
                idx:= plib.add2ir(node);
				plib.add_child(idx,yyv(yypvt-2).node);
				plib.add_sibling(idx,yyv(yypvt-0).node);
				yyval.node := idx;
            
elsif yym = 208 then
--# line 1474 "PLP.Y"
                plib.set_node( node, IN_, yyv(yypvt-4).line, yyv(yypvt-4).pos );
                idx:= plib.add2ir(node);
				plib.add_child(idx,yyv(yypvt-2).node);
				plib.add_sibling(yyv(yypvt-4).node,idx);
				plib.add_sibling(yyv(yypvt-4).node,yyv(yypvt-0).node);
				yyval.node := yyv(yypvt-4).node;
            
elsif yym = 209 then
--# line 1489 "PLP.Y"
					plib.set_node( node, CASE_, yyv(yypvt-4).line, yyv(yypvt-4).pos );
    				idx:= plib.add2ir(node,yyv(yypvt-3).node);
                    plib.add_child(idx,yyv(yypvt-2).node);
					yyval.node := idx ;
				
elsif yym = 210 then
--# line 1502 "PLP.Y"
                    plib.set_node( node, CASE_, yyv(yypvt-6).line, yyv(yypvt-6).pos );
                    idx:= plib.add2ir(node,yyv(yypvt-5).node);
                    plib.add_child(idx,yyv(yypvt-4).node);
                    plib.add_child(idx,yyv(yypvt-2).node);
                    yyval.node := idx ;
				
elsif yym = 211 then
--# line 1516 "PLP.Y"
                plib.set_node( node, WHEN_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
                yyval.node := plib.add2ir(node,yyv(yypvt-2).node,yyv(yypvt-0).node);
            
elsif yym = 213 then
--# line 1525 "PLP.Y"
				plib.add_sibling(yyv(yypvt-1).node,yyv(yypvt-0).node);
				yyval.node := yyv(yypvt-1).node;
            
elsif yym = 214 then
--# line 1534 "PLP.Y"
				plib.set_node( node, CASE_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
				idx := plib.add2ir( node );
                plib.add_child(idx,yyv(yypvt-1).node);
				yyval.node := idx ;
			
elsif yym = 215 then
--# line 1544 "PLP.Y"
				plib.set_node( node, CASE_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
				idx := plib.add2ir( node, yyv(yypvt-2).node );
                plib.add_child(idx,yyv(yypvt-1).node);
				yyval.node := idx ;
			
elsif yym = 216 then
--# line 1555 "PLP.Y"
                plib.set_node( node, CASE_, yyv(yypvt-4).line, yyv(yypvt-4).pos );
				idx := plib.add2ir( node );
				plib.set_node( node, ELSE_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
				idx1 := plib.add2ir( node, yyv(yypvt-1).node );
                plib.add_child(idx,yyv(yypvt-3).node);
                plib.add_child(idx,idx1);
                yyval.node := idx ;
			
elsif yym = 217 then
--# line 1570 "PLP.Y"
                plib.set_node( node, CASE_, yyv(yypvt-5).line, yyv(yypvt-5).pos );
				idx := plib.add2ir( node, yyv(yypvt-4).node );
				plib.set_node( node, ELSE_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
				idx1 := plib.add2ir( node, yyv(yypvt-1).node );
                plib.add_child(idx,yyv(yypvt-3).node);
                plib.add_child(idx,idx1);
                yyval.node := idx ;
			
elsif yym = 218 then
--# line 1583 "PLP.Y"
					plib.set_node( node, RETURN_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
					yyval.node := plib.add2ir( node );
				
elsif yym = 219 then
--# line 1590 "PLP.Y"
					plib.set_node( node, RETURN_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
					yyval.node := plib.add2ir( node, yyv(yypvt-1).node );
				
elsif yym = 220 then
--# line 1598 "PLP.Y"
                    plib.set_node( node, RAISE_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
					yyval.node := plib.add2ir(node);
				
elsif yym = 221 then
--# line 1605 "PLP.Y"
                    plib.set_node( node, RAISE_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
                    yyval.node := plib.add2ir( node, yyv(yypvt-1).node );
                
elsif yym = 222 then
--# line 1612 "PLP.Y"
                    plib.set_node( node, DECLARE_, null, null );
					idx := plib.add2ir(node);
                    plib.add_sibling(idx,yyv(yypvt-0).node);
					plib.set_node( node, BLOCK_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
                    yyval.node := plib.add2ir(node);
                    plib.add_child(yyval.node,idx);
				
elsif yym = 223 then
--# line 1623 "PLP.Y"
                    plib.add_sibling(yyv(yypvt-1).node,yyv(yypvt-0).node);
                    plib.set_node( node, BLOCK_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
                    yyval.node := plib.add2ir(node);
                    plib.add_child(yyval.node,yyv(yypvt-1).node);
		    		plib.process_declare_level();
				
elsif yym = 224 then
--# line 1638 "PLP.Y"
						plib.set_node( node, INSERT_, yyv(yypvt-5).line, yyv(yypvt-5).pos );
                        idx := plib.add2ir( node, yyv(yypvt-3).node, yyv(yypvt-1).node );
                        plib.add_child(idx,yyv(yypvt-4).node);
                        yyval.node := idx;
					
elsif yym = 225 then
--# line 1655 "PLP.Y"
                        plib.set_node( node, REF_, yyv(yypvt-6).line, yyv(yypvt-6).pos );
						idx := plib.add2ir( node );
						plib.set_node( node, ID_, yyv(yypvt-6).line, yyv(yypvt-6).pos, yyv(yypvt-6).text );
						idx := plib.add2ir( node, idx );
                        plib.set_node( node, WHERE_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
                        idx1:= plib.add2ir(node, yyv(yypvt-2).node);
                        plib.set_node( node, INSERT_, yyv(yypvt-10).line, yyv(yypvt-10).pos, yyv(yypvt-6).text, null, SELECT_ );
                        idx := plib.add2ir(node, idx, yyv(yypvt-8).node, idx1, yyv(yypvt-1).node);
                        plib.add_child(idx,yyv(yypvt-4).node);
                        plib.add_child(idx,yyv(yypvt-7).node,false);
                        yyval.node := idx;
					
elsif yym = 226 then
--# line 1675 "PLP.Y"
                    yyval.node := yyv(yypvt-3).node;
				
elsif yym = 227 then
--# line 1683 "PLP.Y"
							plib.set_node( node, WHILE_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
                            yyval.node := plib.add2ir( node, yyv(yypvt-1).node, yyv(yypvt-0).node );
						
elsif yym = 228 then
--# line 1695 "PLP.Y"
						plib.set_node( node, INTEGER_, yyv(yypvt-4).line, yyv(yypvt-4).pos );
						idx := plib.add2ir( node );
						plib.set_node( node, ID_, yyv(yypvt-4).line, yyv(yypvt-4).pos, yyv(yypvt-4).text );
						idx := plib.add2ir( node, idx );
						plib.set_node( node, FOR_, yyv(yypvt-5).line, yyv(yypvt-5).pos, yyv(yypvt-4).text, yyv(yypvt-2).text );
                        yyval.node := plib.add2ir( node, idx, yyv(yypvt-1).node, yyv(yypvt-0).node );
					
elsif yym = 229 then
--# line 1708 "PLP.Y"
                        plib.set_node( node, ID_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
						idx := plib.add2ir( node );
                        plib.set_node( node, ID_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
						idx := plib.add2ir( node, idx );
                        plib.set_node( node,FOR_, yyv(yypvt-4).line, yyv(yypvt-4).pos );
                        yyval.node := plib.add2ir( node, idx, yyv(yypvt-2).node, yyv(yypvt-0).node );
					
elsif yym = 230 then
--# line 1722 "PLP.Y"
						plib.set_node( node, FOR_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
						yyval.node := plib.add2ir( node, yyv(yypvt-3).node, yyv(yypvt-1).node, yyv(yypvt-0).node );
					
elsif yym = 231 then
--# line 1733 "PLP.Y"
                        plib.set_node( node, WHERE_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
                        idx := plib.add2ir(node, yyv(yypvt-3).node);
                        plib.set_node( node, ORDER_, yyv(yypvt-2).line, yyv(yypvt-2).pos, plib.collect_text(yyv(yypvt-2).node, FALSE, FALSE, FALSE) );
						idx1 := plib.add2ir(node);
                        plib.add_child( idx1, yyv(yypvt-2).node);
                        plib.set_node( node, IN_, yyv(yypvt-6).line, yyv(yypvt-6).pos, NULL, yyv(yypvt-4).text, yyv(yypvt-5).node+yyv(yypvt-1).node+yyv(yypvt-0).node );
                        yyval.node := plib.add2ir( node, yyv(yypvt-6).node, idx, idx1 );
					
elsif yym = 232 then
--# line 1744 "PLP.Y"
                        plib.set_node( node, CURSOR_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
                        yyval.node := plib.add2ir( node,yyv(yypvt-0).node );
					
elsif yym = 233 then
--# line 1760 "PLP.Y"
                        plib.set_node( node, WHERE_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
                        idx := plib.add2ir(node, yyv(yypvt-3).node);
                        plib.set_node( node, ORDER_, yyv(yypvt-2).line, yyv(yypvt-2).pos, plib.collect_text(yyv(yypvt-2).node, FALSE, FALSE, FALSE) );
                        idx1 := plib.add2ir(node);
                        plib.add_child(idx1,yyv(yypvt-2).node);
                        plib.set_node( node, LOCATE_, yyv(yypvt-9).line, yyv(yypvt-9).pos, yyv(yypvt-8).text, null,yyv(yypvt-4).node+yyv(yypvt-1).node );
                        yyval.node := plib.add2ir( node, yyv(yypvt-7).node, yyv(yypvt-5).node, idx, idx1 );
					
elsif yym = 234 then
--# line 1772 "PLP.Y"
                if substr(yyv(yypvt-0).text,1,1)='%' then
                    yyval.node := LOCK_REF_+4000;
                else
                    yyval.node := LOCK_REF_;
                end if;
            
elsif yym = 235 then
--# line 1780 "PLP.Y"
                if substr(yyv(yypvt-0).text,1,1)='%' then
                    yyval.node := OBJECT_REF_+4000;
                else
                    yyval.node := OBJECT_REF_;
                end if;
            
elsif yym = 236 then
--# line 1790 "PLP.Y"
		 		yyval.text := 'A';
		 	
elsif yym = 237 then
--# line 1794 "PLP.Y"
		 		yyval.text := 'A';
		 	
elsif yym = 238 then
--# line 1798 "PLP.Y"
		 		yyval.text := 'D';
		 	
elsif yym = 239 then
--# line 1803 "PLP.Y"
		 		yyval.text := upper(substr(yyv(yypvt-0).text,1,1));
		 	
elsif yym = 240 then
--# line 1808 "PLP.Y"
		 		yyval.text := substr(yyv(yypvt-0).text,1,1);
		 	
elsif yym = 241 then
--# line 1815 "PLP.Y"
					plib.set_text(yyv(yypvt-1).node, NULL, yyv(yypvt-0).text);
					yyval.node := yyv(yypvt-1).node;
				
elsif yym = 242 then
--# line 1822 "PLP.Y"
					yyval.node := yyv(yypvt-0).node;
				
elsif yym = 243 then
--# line 1828 "PLP.Y"
					yyval.node := yyv(yypvt-2).node;
					plib.add_sibling( yyv(yypvt-2).node, yyv(yypvt-0).node);
				
elsif yym = 244 then
--# line 1835 "PLP.Y"
				yyval.node := NULL;
			
elsif yym = 245 then
--# line 1841 "PLP.Y"
                plib.ir(yyv(yypvt-0).node).text1 := yyv(yypvt-1).text||'.'||plib.ir(yyv(yypvt-0).node).text1;
				yyval.node := yyv(yypvt-0).node;
			
elsif yym = 246 then
--# line 1859 "PLP.Y"
                        plib.set_node( node, REF_, yyv(yypvt-9).line, yyv(yypvt-9).pos );
						idx := plib.add2ir( node );
						plib.set_node( node, ID_, yyv(yypvt-9).line, yyv(yypvt-9).pos, yyv(yypvt-9).text );
						idx := plib.add2ir( node, idx );
                        plib.set_node( node, WHERE_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
                        idx1:= plib.add2ir(node, yyv(yypvt-2).node);
                        plib.set_node( node, UPDATE_, yyv(yypvt-11).line, yyv(yypvt-11).pos, yyv(yypvt-9).text, null, yyv(yypvt-3).node );
                        yyval.node := plib.add2ir(node, idx, yyv(yypvt-4).node, idx1, yyv(yypvt-1).node);
                        plib.add_child(yyval.node,yyv(yypvt-7).node);
                        plib.add_child(yyval.node,yyv(yypvt-10).node,false);
					
elsif yym = 247 then
--# line 1882 "PLP.Y"
                        plib.set_node( node, REF_, yyv(yypvt-6).line, yyv(yypvt-6).pos );
						idx := plib.add2ir( node );
						plib.set_node( node, ID_, yyv(yypvt-6).line, yyv(yypvt-6).pos, yyv(yypvt-6).text );
						idx := plib.add2ir( node, idx );
                        plib.set_node( node, WHERE_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
                        idx1:= plib.add2ir(node, yyv(yypvt-2).node);
                        plib.set_node( node, DELETE_, yyv(yypvt-8).line, yyv(yypvt-8).pos, yyv(yypvt-6).text, null, yyv(yypvt-3).node );
                        yyval.node := plib.add2ir(node, idx, yyv(yypvt-4).node, idx1, yyv(yypvt-1).node);
                        plib.add_child(yyval.node,yyv(yypvt-7).node,false);
					
elsif yym = 248 then
--# line 1907 "PLP.Y"
                        plib.set_node( node, SELECT_, yyv(yypvt-7).line, yyv(yypvt-7).pos );
                        idx := plib.add2ir(node);
                        plib.add_child(idx, yyv(yypvt-7).node);
                        plib.set_node( node, WHERE_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
                        idx1 := plib.add2ir(node, yyv(yypvt-3).node);
                        if not yyv(yypvt-2).node is null then
                            if yyv(yypvt-3).node is null then
                                plib.add_child(idx1,plib.add2ir(BOOLEAN_,CONSTANT_,'true','C'));
                            end if;
                            plib.add_child(idx1,yyv(yypvt-2).node);
                        end if;
                        plib.set_node( node, SELECT_, yyv(yypvt-11).line, yyv(yypvt-11).pos, yyv(yypvt-9).text, yyv(yypvt-10).text, yyv(yypvt-4).node );
                        yyval.node := plib.add2ir(node, yyv(yypvt-5).node, idx, idx1);
                        plib.set_node( node, REF_, yyv(yypvt-9).line, yyv(yypvt-9).pos );
						idx := plib.add2ir( node );
                        plib.set_node( node, ID_, yyv(yypvt-9).line, yyv(yypvt-9).pos, yyv(yypvt-9).text );
						idx := plib.add2ir( node, idx );
                        plib.add_child(yyval.node, idx, false);
                        plib.set_node( node, GROUP_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
                        idx := plib.add2ir(node);
                        plib.add_child(idx, yyv(yypvt-1).node);
                        plib.add_child(yyval.node,idx);
                        plib.set_node( node, HAVING_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
                        idx := plib.add2ir(node,yyv(yypvt-0).node);
                        plib.add_child(yyval.node,idx);
					
elsif yym = 249 then
--# line 1938 "PLP.Y"
                        plib.set_node( node, ID_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
						idx := plib.add2ir( node );
                        plib.set_node( node, ID_, yyv(yypvt-2).line, yyv(yypvt-2).pos, plib.ir(plib.ir(yyv(yypvt-2).node).down).text );
						idx := plib.add2ir( node, idx );
                        plib.set_node( node, SELECT_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text, NULL, UNION_ );
                        yyval.node := plib.add2ir(node,idx,yyv(yypvt-2).node,yyv(yypvt-0).node);
                    
elsif yym = 250 then
--# line 1951 "PLP.Y"
                        plib.set_node( node, ID_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
						idx := plib.add2ir( node );
                        plib.set_node( node, ID_, yyv(yypvt-3).line, yyv(yypvt-3).pos, plib.ir(plib.ir(yyv(yypvt-3).node).down).text );
						idx := plib.add2ir( node, idx );
                        plib.set_node( node, SELECT_, yyv(yypvt-2).line, yyv(yypvt-2).pos, yyv(yypvt-2).text, 'P', UNION_ );
                        yyval.node := plib.add2ir(node,idx,yyv(yypvt-3).node,yyv(yypvt-1).node);
                    
elsif yym = 251 then
--# line 1964 "PLP.Y"
                        idx1:= yyv(yypvt-2).node;
                        plib.set_node( node, ORDER_, yyv(yypvt-1).line, yyv(yypvt-1).pos, plib.collect_text(yyv(yypvt-1).node, FALSE, FALSE, FALSE) );
                        idx := plib.add2ir(node);
                        plib.add_child(idx,yyv(yypvt-1).node);
                        plib.add_child(idx1,idx);
                        plib.add_child(idx1,yyv(yypvt-0).node);
                        yyval.node := idx1;
					
elsif yym = 252 then
--# line 1976 "PLP.Y"
			yyval.text := NULL;
		
elsif yym = 257 then
--# line 1987 "PLP.Y"
                yyval.text := yyv(yypvt-1).text||' '||yyv(yypvt-0).text;
			
elsif yym = 258 then
--# line 1992 "PLP.Y"
                yyval.text := yyv(yypvt-1).text||' '||yyv(yypvt-0).text;
			
elsif yym = 259 then
--# line 1997 "PLP.Y"
                yyval.text := yyv(yypvt-1).text||' '||yyv(yypvt-0).text;
			
elsif yym = 260 then
--# line 2002 "PLP.Y"
                yyval.text := yyv(yypvt-1).text||' '||yyv(yypvt-0).text;
			
elsif yym = 261 then
--# line 2007 "PLP.Y"
                yyval.text := yyv(yypvt-1).text||' '||yyv(yypvt-0).text;
			
elsif yym = 262 then
--# line 2012 "PLP.Y"
                yyval.text := yyv(yypvt-1).text||' '||yyv(yypvt-0).text;
			
elsif yym = 263 then
--# line 2018 "PLP.Y"
				yyval.text := NULL;
			
elsif yym = 265 then
--# line 2024 "PLP.Y"
                yyval.text := yyv(yypvt-0).text;
			
elsif yym = 266 then
--# line 2030 "PLP.Y"
				yyval.text := NULL;
			
elsif yym = 268 then
--# line 2037 "PLP.Y"
			yyval.node := NULL;
		
elsif yym = 269 then
--# line 2042 "PLP.Y"
			yyval.node := yyv(yypvt-0).node;
		
elsif yym = 270 then
--# line 2048 "PLP.Y"
			yyval.node := NULL;
		
elsif yym = 271 then
--# line 2053 "PLP.Y"
			yyval.node := yyv(yypvt-0).node;
		
elsif yym = 272 then
--# line 2059 "PLP.Y"
			yyval.node := NULL;
		
elsif yym = 273 then
--# line 2065 "PLP.Y"
            yyval.node := yyv(yypvt-0).node;
		
elsif yym = 274 then
--# line 2071 "PLP.Y"
			yyval.node := NULL;
		
elsif yym = 275 then
--# line 2077 "PLP.Y"
			plib.set_text(yyv(yypvt-0).node, NULL, yyv(yypvt-1).text);
            yyval.node := yyv(yypvt-0).node;
		
elsif yym = 276 then
--# line 2086 "PLP.Y"
			plib.set_text(yyv(yypvt-2).node, NULL, yyv(yypvt-3).text);
            yyval.node := yyv(yypvt-2).node;
            plib.add_sibling( yyv(yypvt-2).node, yyv(yypvt-0).node);
		
elsif yym = 277 then
--# line 2094 "PLP.Y"
            yyval.node := 1;
		
elsif yym = 278 then
--# line 2099 "PLP.Y"
			yyval.node := 1;
		
elsif yym = 279 then
--# line 2104 "PLP.Y"
            yyval.node := 999;
		
elsif yym = 280 then
--# line 2110 "PLP.Y"
            idx := yyv(yypvt-0).text;
            if idx>998 then idx:=998; end if;
            yyval.node := idx+1;
		
elsif yym = 281 then
--# line 2118 "PLP.Y"
            yyval.node := 0;
		
elsif yym = 282 then
--# line 2122 "PLP.Y"
            yyval.node := yyv(yypvt-0).node;
		
elsif yym = 283 then
--# line 2128 "PLP.Y"
            yyval.node := 0;
		
elsif yym = 284 then
--# line 2132 "PLP.Y"
            yyval.node := 1000;
		
elsif yym = 285 then
--# line 2136 "PLP.Y"
            yyval.node := 2000;
		
elsif yym = 286 then
--# line 2141 "PLP.Y"
            yyval.node := 3000;
		
elsif yym = 287 then
--# line 2146 "PLP.Y"
            yyval.node := 4000;
		
elsif yym = 288 then
--# line 2152 "PLP.Y"
            yyval.node := 0;
		
elsif yym = 289 then
--# line 2158 "PLP.Y"
            yyval.node := 10000;
		
elsif yym = 290 then
--# line 2164 "PLP.Y"
			yyval.node := NULL;
		
elsif yym = 291 then
--# line 2171 "PLP.Y"
            plib.set_node( node, INTO_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
            idx := plib.add2ir( node );
            plib.add_child(idx,yyv(yypvt-0).node);
            plib.set_node( node, SELECT_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
            idx1 := plib.add2ir( node );
            plib.add_child(idx1,yyv(yypvt-2).node);
            plib.set_node( node, RETURN_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
            yyval.node := plib.add2ir( node,idx,idx1 );
        
elsif yym = 292 then
--# line 2184 "PLP.Y"
			yyval.node := NULL;
		
elsif yym = 293 then
--# line 2194 "PLP.Y"
			plib.set_node( node, INTEGER_, yyv(yypvt-5).line, yyv(yypvt-5).pos, yyv(yypvt-0).text );
			idx := plib.add2ir( node, yyv(yypvt-3).node, yyv(yypvt-1).node );
			plib.set_node( node, ID_, yyv(yypvt-5).line, yyv(yypvt-5).pos, yyv(yypvt-5).text );
			yyval.node := plib.add2ir( node, idx );
        
elsif yym = 294 then
--# line 2205 "PLP.Y"
			plib.set_node( node, INTEGER_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-0).text, yyv(yypvt-2).text );
			idx := plib.add2ir( node, yyv(yypvt-1).node );
			plib.set_node( node, ID_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-3).text );
			yyval.node := plib.add2ir( node, idx );
        
elsif yym = 295 then
--# line 2216 "PLP.Y"
			plib.set_node( node, INTEGER_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-0).text, yyv(yypvt-2).text );
			idx := plib.add2ir( node, yyv(yypvt-1).node );
			plib.set_node( node, ID_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-3).text );
			yyval.node := plib.add2ir( node, idx );
        
elsif yym = 296 then
--# line 2231 "PLP.Y"
			plib.set_node( node, INTEGER_, yyv(yypvt-7).line, yyv(yypvt-7).pos, yyv(yypvt-0).text, yyv(yypvt-6).text );
			idx := plib.add2ir( node, yyv(yypvt-5).node, yyv(yypvt-3).node, yyv(yypvt-1).node );
			plib.set_node( node, ID_, yyv(yypvt-7).line, yyv(yypvt-7).pos, yyv(yypvt-7).text );
			yyval.node := plib.add2ir( node, idx );
        
elsif yym = 297 then
--# line 2241 "PLP.Y"
			    plib.set_node( node, ASSIGN_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-1).text );
    			yyval.node := plib.add2ir( node, yyv(yypvt-0).node );
			
elsif yym = 298 then
--# line 2248 "PLP.Y"
				yyval.node := yyv(yypvt-0).node;
	   		
elsif yym = 299 then
--# line 2254 "PLP.Y"
				yyval.node := yyv(yypvt-2).node;
				plib.add_sibling(yyv(yypvt-2).node, yyv(yypvt-0).node);
	   		
elsif yym = 300 then
--# line 2261 "PLP.Y"
				yyval.node := NULL;
			
elsif yym = 301 then
--# line 2266 "PLP.Y"
			    plib.set_node( node, BY_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
    			idx := plib.add2ir( node );
                plib.add_child(idx,yyv(yypvt-0).node);
                yyval.node := idx;
			
elsif yym = 302 then
--# line 2279 "PLP.Y"
			        plib.set_node( node, ANY_, yyv(yypvt-4).line, yyv(yypvt-4).pos, yyv(yypvt-4).text );
    			    yyval.node := plib.add2ir( node, yyv(yypvt-2).node, yyv(yypvt-1).node );
                
elsif yym = 303 then
--# line 2290 "PLP.Y"
			        plib.set_node( node, INTO_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
    			    idx := plib.add2ir( node );
                    plib.add_child(idx,yyv(yypvt-2).node);
			        plib.set_node( node, ANY_, yyv(yypvt-6).line, yyv(yypvt-6).pos, yyv(yypvt-6).text );
    			    yyval.node := plib.add2ir( node, yyv(yypvt-4).node, idx, yyv(yypvt-1).node );
                
elsif yym = 304 then
--# line 2305 "PLP.Y"
			        plib.set_node( node, RETURN_, yyv(yypvt-3).line, yyv(yypvt-3).pos );
    			    idx := plib.add2ir( node );
                    plib.add_child(idx,yyv(yypvt-1).node);
			        plib.set_node( node, ANY_, yyv(yypvt-7).line, yyv(yypvt-7).pos, yyv(yypvt-7).text );
    			    yyval.node := plib.add2ir( node, yyv(yypvt-5).node, idx, yyv(yypvt-4).node );
                
elsif yym = 305 then
--# line 2315 "PLP.Y"
						plib.set_node( node, SOS_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
						yyval.node := plib.add2ir(node, yyv(yypvt-0).node);
					
elsif yym = 306 then
--# line 2321 "PLP.Y"
						yyval.node := yyv(yypvt-1).node;
						plib.add_child(yyv(yypvt-1).node, yyv(yypvt-0).node);
					
elsif yym = 307 then
--# line 2331 "PLP.Y"
                        plib.set_node( node, WHEN_, yyv(yypvt-2).line, yyv(yypvt-2).pos );
                        yyval.node := plib.add2ir(node, yyv(yypvt-2).node, yyv(yypvt-0).node);
                    
elsif yym = 308 then
--# line 2341 "PLP.Y"
                        plib.set_node( node, OTHERS_, yyv(yypvt-3).line, yyv(yypvt-3).pos, null, null, yyv(yypvt-2).node);
                        yyval.node := plib.add2ir(node, yyv(yypvt-0).node);
                    
elsif yym = 310 then
--# line 2350 "PLP.Y"
                        plib.add_sibling(yyv(yypvt-1).node, yyv(yypvt-0).node);
						yyval.node := yyv(yypvt-1).node;
					
elsif yym = 311 then
--# line 2357 "PLP.Y"
				plib.set_node( node, EXCEPTION_ );
				yyval.node := plib.add2ir(node);
			
elsif yym = 312 then
--# line 2363 "PLP.Y"
				plib.set_node( node, EXCEPTION_ );
				yyval.node := plib.add2ir(node);
				plib.add_child(yyval.node, yyv(yypvt-0).node);
			
elsif yym = 313 then
--# line 2371 "PLP.Y"
				plib.set_node( node, INTEGER_ );
                idx := plib.add2ir(node);
				plib.set_node( node, BOOLEAN_ );
				idx1 := plib.add2ir(node);
                plib.add_sibling(idx,idx1);
				plib.set_node( node, INTEGER_ );
				idx1 := plib.add2ir(node);
                plib.add_sibling(idx,idx1);
                yyval.node := idx;
			
elsif yym = 314 then
--# line 2385 "PLP.Y"
                idx := yyv(yypvt-0).node;
				plib.set_node( node, BOOLEAN_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
				idx1:= plib.add2ir(node);
                plib.add_sibling(idx,idx1);
				plib.set_node( node, INTEGER_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
				idx1:= plib.add2ir(node);
                plib.add_sibling(idx,idx1);
				yyval.node := idx;
			
elsif yym = 315 then
--# line 2398 "PLP.Y"
				yyval.node := yyv(yypvt-0).node;
			
elsif yym = 316 then
--# line 2404 "PLP.Y"
				yyval.node := yyv(yypvt-2).node;
				plib.add_sibling(yyv(yypvt-2).node, yyv(yypvt-0).node);
			
elsif yym = 317 then
--# line 2411 "PLP.Y"
                yyval.node := null;
			
elsif yym = 318 then
--# line 2418 "PLP.Y"
                plib.set_node(node, LOCK_, yyv(yypvt-3).line, yyv(yypvt-3).pos , null, null, yyv(yypvt-3).node);
                yyval.node := plib.add2ir(node);
                plib.add_child(yyval.node, yyv(yypvt-1).node);
			
elsif yym = 319 then
--# line 2425 "PLP.Y"
                plib.set_node(node, OTHERS_, yyv(yypvt-1).line, yyv(yypvt-1).pos);
                yyval.node := plib.add2ir(node,yyv(yypvt-0).node);
		    
elsif yym = 320 then
--# line 2432 "PLP.Y"
                plib.set_node(node, ASSIGN_, yyv(yypvt-0).line, yyv(yypvt-0).pos);
                yyval.node := plib.add2ir(node, yyv(yypvt-0).node);
            
elsif yym = 321 then
--# line 2438 "PLP.Y"
                plib.set_node(node, ASSIGN_, yyv(yypvt-1).line, yyv(yypvt-1).pos, yyv(yypvt-0).text);
                yyval.node := plib.add2ir(node, yyv(yypvt-1).node);
            
elsif yym = 322 then
--# line 2445 "PLP.Y"
                plib.set_node(node, ASSIGN_, yyv(yypvt-2).line, yyv(yypvt-2).pos, yyv(yypvt-0).text);
                yyval.node := plib.add2ir(node, yyv(yypvt-2).node);
            
elsif yym = 323 then
--# line 2452 "PLP.Y"
				yyval.node := yyv(yypvt-0).node;
			
elsif yym = 324 then
--# line 2458 "PLP.Y"
				yyval.node := yyv(yypvt-2).node;
				plib.add_sibling(yyv(yypvt-2).node, yyv(yypvt-0).node);
			
elsif yym = 325 then
--# line 2470 "PLP.Y"
                plib.set_node(node, IN_, yyv(yypvt-4).line, yyv(yypvt-4).pos , yyv(yypvt-1).text, null, yyv(yypvt-3).node);
                yyval.node := plib.add2ir(node,yyv(yypvt-4).node);
			
elsif yym = 326 then
--# line 2479 "PLP.Y"
                plib.set_node(node, IN_, yyv(yypvt-3).line, yyv(yypvt-3).pos , yyv(yypvt-1).text, null, yyv(yypvt-2).node);
                yyval.node := plib.add2ir(node,yyv(yypvt-3).node);
			
elsif yym = 327 then
--# line 2486 "PLP.Y"
                yyval.node := yyv(yypvt-1).node;
			
elsif yym = 328 then
--# line 2493 "PLP.Y"
                yyval.node := yyv(yypvt-0).node;
			
elsif yym = 329 then
--# line 2498 "PLP.Y"
                yyval.node := yyv(yypvt-0).node;
			
elsif yym = 330 then
--# line 2504 "PLP.Y"
                idx := yyv(yypvt-2).node;
                if plib.get_type(idx)<>IN_ then
                    plib.set_node(node, IN_, yyv(yypvt-2).line, yyv(yypvt-2).pos);
                    idx := plib.add2ir(node,yyv(yypvt-2).node);
                end if;
                plib.add_child(idx, yyv(yypvt-0).node);
                yyval.node := idx;
			
elsif yym = 331 then
--# line 2518 "PLP.Y"
                plib.set_node(node, ASSIGN_, yyv(yypvt-1).line, yyv(yypvt-1).pos);
                yyval.node := plib.add2ir(node,yyv(yypvt-2).node,yyv(yypvt-0).node);
            
elsif yym = 332 then
--# line 2529 "PLP.Y"
                plib.set_node(node, IN_, yyv(yypvt-6).line, yyv(yypvt-6).pos);
                idx := plib.add2ir(node);
                plib.add_child(idx, yyv(yypvt-5).node);
                plib.set_node(node, ASSIGN_, yyv(yypvt-3).line, yyv(yypvt-3).pos);
                yyval.node := plib.add2ir(node,idx,yyv(yypvt-1).node);
            
elsif yym = 333 then
--# line 2539 "PLP.Y"
				yyval.node := yyv(yypvt-0).node;
			
elsif yym = 334 then
--# line 2545 "PLP.Y"
				yyval.node := yyv(yypvt-2).node;
				plib.add_sibling(yyv(yypvt-2).node, yyv(yypvt-0).node);
			
elsif yym = 335 then
--# line 2552 "PLP.Y"
					plib.set_node( node, DECLARE_ );
					yyval.node := plib.add2ir(node);
				
elsif yym = 337 then
--# line 2560 "PLP.Y"
					plib.set_node( node, DECLARE_, yyv(yypvt-0).line, yyv(yypvt-0).pos );
					yyval.node := plib.add2ir(node, yyv(yypvt-0).node);
				
elsif yym = 338 then
--# line 2566 "PLP.Y"
					yyval.node := yyv(yypvt-1).node;
					plib.add_child(yyval.node, yyv(yypvt-0).node);
				
elsif yym = 339 then
--# line 2572 "PLP.Y"
					yyerrok;
					yyclearin;
					plib.set_node( node, INVALID_ );
					yyval.node := plib.add2ir(node);
				
elsif yym = 340 then
--# line 2585 "PLP.Y"
                    plib.add_sibling(yyv(yypvt-3).node,yyv(yypvt-2).node);
                    yyval.node := yyv(yypvt-3).node;
		    		plib.process_declare_level();
				
elsif yym = 341 then
--# line 2595 "PLP.Y"
                    plib.set_node( node, BLOCK_, yyv(yypvt-1).line, yyv(yypvt-1).pos );
                    plib.add_sibling(yyv(yypvt-1).node,yyv(yypvt-0).node);
                    yyval.node := plib.add2ir(node);
                    plib.add_child(yyval.node,yyv(yypvt-1).node);
				
elsif yym = 342 then
--# line 2603 "PLP.Y"
    				yyval.node := NULL;
    			
elsif yym = 343 then
--# line 2612 "PLP.Y"
					plib.set_node( node, INVALID_ );
					idx := plib.add2ir(node);
					plib.set_node( node, FUNCTION_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-2).text );
                    yyval.node := plib.add2ir(node, idx, yyv(yypvt-1).node, yyv(yypvt-0).node);
                    plib.process_declare_level();
				
elsif yym = 344 then
--# line 2623 "PLP.Y"
					plib.set_node( node, INVALID_ );
					idx := plib.add2ir(node);
					plib.set_node( node, FUNCTION_, yyv(yypvt-3).line, yyv(yypvt-3).pos, yyv(yypvt-2).text );
                    yyval.node := plib.add2ir(node, idx, yyv(yypvt-1).node);
                    plib.process_declare_level();
				
elsif yym = 345 then
--# line 2633 "PLP.Y"
				yyval.text := NULL;
			
elsif yym = 347 then
--# line 2639 "PLP.Y"
                yyval.text := yyv(yypvt-1).text||' '||yyv(yypvt-0).text;
			
elsif yym = 348 then
--# line 2645 "PLP.Y"
                yyval.text := yyv(yypvt-2).text||' '||yyv(yypvt-1).text||' '||yyv(yypvt-0).text;
			
elsif yym = 349 then
--# line 2656 "PLP.Y"
					plib.set_node( node, FUNCTION_, yyv(yypvt-5).line, yyv(yypvt-5).pos, yyv(yypvt-4).text );
                    yyval.node := plib.add2ir(node, yyv(yypvt-1).node, yyv(yypvt-3).node, yyv(yypvt-0).node);
                    plib.process_declare_level();
				
elsif yym = 350 then
--# line 2668 "PLP.Y"
					plib.set_node( node, FUNCTION_, yyv(yypvt-6).line, yyv(yypvt-6).pos, yyv(yypvt-5).text, yyv(yypvt-1).text );
                    yyval.node := plib.add2ir(node, yyv(yypvt-2).node, yyv(yypvt-4).node);
                    plib.process_declare_level();
				
elsif yym = 351 then
--# line 2681 "PLP.Y"
					plib.set_node( node, FUNCTION_, yyv(yypvt-6).line, yyv(yypvt-6).pos, yyv(yypvt-5).text, yyv(yypvt-1).text );
					yyval.node := plib.add2ir(node, yyv(yypvt-2).node, yyv(yypvt-4).node, yyv(yypvt-0).node);
					idx := yyval.node;
					plib.process_public_modifier(idx);	
				
elsif yym = 352 then
--# line 2690 "PLP.Y"
					return yyv(yypvt-0).node;
				
elsif yym = 353 then
--# line 2696 "PLP.Y"
                    idx := yyv(yypvt-0).node;
                    idx1:= plib.ir(idx).down;
                    plib.ir(idx).down := null;
                    plib.delete_node(idx);
                    plib.add_child(yyv(yypvt-2).node,idx1);
                    plib.add_sibling(yyv(yypvt-2).node,yyv(yypvt-1).node);
					return yyv(yypvt-2).node;
				
elsif yym = 354 then
--# line 2706 "PLP.Y"
					return NULL;
				
end if;
	goto yystack;  /* положить в стек новое состояние и значение */
exception
when ABORT then
	return 1;
end yyparse;
--
procedure yyabort is
begin
	raise ABORT;
end yyabort;
--
procedure yyerrok is
begin
	yyerrflag := 0;
end yyerrok;
--
procedure yyclearin is
begin
	yychar := -1;
end yyclearin;
--
function yyback ( p pls_integer, m pls_integer ) return pls_integer is
        pp pls_integer := p;
begin
        if pp = 0 then
                return(0);
        end if;
        while ( vs(pp) != 0 ) loop
                if vs(pp) = m then
                        return 1;
                end if;
                pp := pp + 1;
        end loop;
        return 0;
end yyback;
--
function yylook return pls_integer is
        yystate  pls_integer;
        lsp      pls_integer;
        yyt      pls_integer;
        yyz      pls_integer;
	yych     varchar2(1);
        yyr      pls_integer;
        yylastch pls_integer;
begin
	/* start off machines */
	if not yymorfg then
		yylastch := 1;
		yytext := '';
	else
		yymorfg := False;
		yylastch := length(yytext) + 1;
	end if;
	loop
		lsp := 0;
                yystate := yybgin;
		if yyprevious = YYNEWLINE then
			yystate := yystate + 1;
		end if;
		loop
/*            if yydebug then
				yyoutput( 'state ' || to_char(yystate-1) );
            end if;*/
			yyt := f(yystate);
			if yyt = 0 then             /* may not be any transitions */
				yyz := o(yystate);
				if yyz = 0 then exit; end if;
				if f(yyz) = 0 then exit; end if;
			end if;
                        yych := plib.input; yytext := substr(yytext, 1, yylastch-1) || yych; yylastch := yylastch + 1;
		<<tryagain>>
/*            if yydebug then
				yyoutput( 'symbol ' || '<' || to_char(ascii(yych)) || '>' || yych );
            end if;*/
			yyr := yyt;
			if yyt > 0 then
				yyt := yyr + ascii(yych);
				if yyt <= yytop and v(yyt) = yystate then
					if a(yyt) = YYLERR then       /* error transitions */
						yylastch := yylastch - 1;
                                                plib.unput( substr(yytext, yylastch, 1) );
						exit;
					end if;
					yystate := a(yyt);
					yylstate(lsp) := yystate; lsp := lsp + 1;
					goto contin;
				end if;
--# ifdef YYOPTIM
			elsif yyt < 0 then              /* r < yycrank */
				yyr := -yyt; yyt := yyr;
--                if yydebug then yyoutput( 'compressed state' ); end if;
				yyt := yyt + ascii(yych);
				if yyt <= yytop and v(yyt) = yystate then
					if a(yyt) = YYLERR then       /* error transitions */
						yylastch := yylastch - 1;
                                                plib.unput( substr(yytext, yylastch, 1) );
						exit;
					end if;
					yystate := a(yyt);
					yylstate(lsp) := yystate; lsp := lsp + 1;
					goto contin;
				end if;
				yyt := yyr + m(ascii(yych));
/*                if yydebug then
					yyoutput( 'try to put back char ' || m(ascii(yych)) );
                end if;*/
				if yyt <= yytop and v(yyt) = yystate then
					if a(yyt) = YYLERR then       /* error transition */
						yylastch := yylastch - 1;
                                                plib.unput( substr(yytext, yylastch, 1) );
						exit;
					end if;
					yystate := a(yyt);
					yylstate(lsp) := yystate;
					lsp := lsp + 1;
					goto contin;
				end if;
			end if;
			yystate := o(yystate);
			if yystate != 0 then
				yyt := f(yystate);
				if yyt != 0 then
--                    if yydebug then yyoutput( 'return back to state ' || to_char(yystate-1) ); end if;
					goto tryagain;
				end if;
--# endif
			else
				yylastch := yylastch - 1;
                                plib.unput( substr(yytext, yylastch, 1) );
				exit;
			end if;

		<<contin>>
/*            if yydebug then
				yyoutput( 'state ' || to_char(yystate-1) || ' symbol ' || yych );
            end if;*/
			null;
		end loop;
/*        if yydebug then
			yyoutput( 'lsp = ' || to_char(lsp) );
--!!??			yyoutput( ' stopped on ' || to_char(yylstate(lsp-1)-1) );
			yyoutput( ' with ' || '<' || to_char(ascii(yych)) || '>' || yych );
        end if;*/
		while lsp > 0 loop
			lsp := lsp - 1;
			yylastch := yylastch - 1;
			yytext := substr(yytext, 1, yylastch);
			yyfnd := s(yylstate(lsp));
			if yylstate(lsp) != 0 and yyfnd != 0 and vs(yyfnd) > 0 then
				if e(vs(yyfnd)) != 0 then            /* must backup */
					while yyback(s(yylstate(lsp)),-vs(yyfnd)) != 1 and lsp > 0 loop
						lsp := lsp - 1;
                                                plib.unput( substr(yytext, yylastch, 1) );
						yylastch := yylastch - 1;
					end loop;
				end if;
				yyprevious := substr(yytext, yylastch, 1);
/*                if yydebug then
					yyoutput( 'found ' || yytext || ' action ' || to_char(vs(yyfnd)) );
                end if;*/
				yyfnd := yyfnd + 1;
				return( vs(yyfnd-1) );
			end if;
                        plib.unput( substr(yytext, yylastch, 1) );
		end loop;
		if yytext is NULL or length(yytext) = 0 or substr(yytext, 1, 1) = chr(0) then
			return 0;
		end if;
                yytext := plib.input; yyprevious := substr(yytext, 1, 1);
/*                if yydebug and yyprevious is not NULL then
			yyoutput(yyprevious);
                end if;*/
		yylastch := 1;
--        if yydebug then yyoutput(' '); end if;
	end loop;
end yylook;
--


function yylex return pls_integer is
	nstr pls_integer;
begin
	loop
		nstr := yylook;
		exit when nstr < 0;
<<yyfussy>>
		if nstr = 0 then
			exit;
elsif nstr = 1 then
   
                extractToken;
                if put and not idx is null then return idx; end if;
			
elsif nstr = 2 then

                extractModificator;
                if put and not idx is null then return idx; end if;
			
elsif nstr = 3 then
           begin
                put := plib.plp$parsedef;
                yylval.line:= plib.plp$line;
				yylval.pos := plib.plp$pos;
                plib.get_string(yytext); flag := 0;
                if put then
				  yylval.text := substr( yytext, 2);
				  return STRING_CONST_;
                end if;
              exception when VALUE_ERROR then
                error_value;
              end;
			
elsif nstr = 4 then
         begin
                put := plib.plp$parsedef;
                yylval.line:= plib.plp$line;
				yylval.pos := plib.plp$pos;
				plib.get_comment(yytext,']'); flag := 0;
                if put then
				  yytext := upper(substr(yytext,2,length(yytext)-2));
				  if ltrim(yytext) is NULL then
					yytext := ' ';
				  end if;
				  yylval.text := yytext;
				  return(DBOBJECT_);
                end if;
              exception when VALUE_ERROR then
                error_value;
              end;
			
elsif nstr = 5 then
         begin
                put := plib.plp$parsedef;
                yylval.line:= plib.plp$line;
				yylval.pos := plib.plp$pos;
				plib.get_comment(yytext,'}'); flag := 0;
				if put then
                  yylval.text := substr(yytext,2,length(yytext)-2);
                  return(NULL_);
                end if;
              exception when VALUE_ERROR then
                error_value;
              end;
			
elsif nstr = 6 then
   
				lset; flag := 13;
				if put then return(DIGIT_); end if;
			
elsif nstr = 7 then

				lset;
				if put then return(NUMBER_CONST_); end if;
			
elsif nstr = 8 then
   
            lset; if put then return(ASSIGN_); end if; 
elsif nstr = 9 then
   
            lset; if put then return(CONCAT_); end if; 
elsif nstr = 10 then
   
            lset; if put then return(NE_); end if; 
elsif nstr = 11 then
   
            lset; if put then return(NE_); end if; 
elsif nstr = 12 then
   
            lset; if put then return(GE_); end if; 
elsif nstr = 13 then
   
            lset; if put then return(LE_); end if; 
elsif nstr = 14 then
   
            lset; if put then return(LABEL_); end if; 
elsif nstr = 15 then
   
            lset; if put then return(LABEL_); end if; 
elsif nstr = 16 then
   
            lset; if put then return(PERIODS_); end if; 
elsif nstr = 17 then
   
            lset; if put then return(CLASS_REF_); end if; 
elsif nstr = 18 then
  
            lset; if put then return(OBJECT_REF_); end if; 
elsif nstr = 19 then
  
            lset; if put then return(LOCK_REF_); end if; 
elsif nstr = 20 then
   
            lset; if put then return(OBJECT_REF_); end if; 
elsif nstr = 21 then
   
            lset; if put then return(LOCK_REF_); end if; 
elsif nstr = 22 then
   
            lset; if put then return(SETPAR_); end if; 
elsif nstr = 23 then
   
            lset; if put then return(POWER_); end if; 
elsif nstr = 24 then

                    yytext := upper(substr(yytext,2));
                    if plib.is_defined(yytext) then
                      plib.insert_macro(yytext);
                    else
                      lset;
                      if put then return(ID_); end if;
                    end if;
				
elsif nstr = 25 then
  
                      begin
                        put := plib.plp$parsedef;
                        yylval.line:= plib.plp$line;
                        yylval.pos := plib.plp$pos - 14;
        				plib.get_comment(yytext,'-- END PL/SQL'); flag := 0;
						if put then
                          yylval.text := yytext||chr(10);
                          plib.g_method_text:=FALSE;
						  return(TEXT_);
                        end if;
                      exception when VALUE_ERROR then
                        error_value;
                      end;
					
elsif nstr = 26 then
		
				plib.get_comment(yytext,chr(10));
                if flag=100 and substr(yytext,3,1)='+' then
				    plib.add2comments(yylval.line,yylval.pos,rtrim(ltrim(yytext,' -+'||chr(9)),' '||chr(9)||chr(10)||chr(13)));
                    flag := 0;
                elsif substr(yytext,3,1)='#' then
                    to_change_level := false;
                    plib.parse_command(yytext);
                    to_change_level := true;
                    flag := 0;
                end if;
			
elsif nstr = 27 then
		
				plib.get_comment(yytext,'*/');
                if flag=100 and substr(yytext,3,1)='+' then
				    plib.add2comments(yylval.line,yylval.pos,rtrim(ltrim(yytext,' /*+'||chr(9)||chr(10)||chr(13)),' */'||chr(9)||chr(10)||chr(13)));
                    flag := 0;
                elsif substr(yytext,3,1)='#' then
                    to_change_level := false;
                    plib.parse_command(yytext);
                    to_change_level := true;
                    flag := 0;
                end if;
			
elsif nstr = 28 then
 
                    yytext := substr(yytext,2);
					lsetu;
					if put then return(ID_); end if;
                  
elsif nstr = 29 then

                yytext := upper(substr(yytext,2));
                if yytext in ('IF','ELSIF') then
				    plib.get_comment(yytext,'$THEN');
                    yytext := '/*#'||substr(yytext,1,length(yytext)-3);
                    plib.parse_command(yytext);
                elsif yytext = 'ERROR' then
				    plib.get_comment(yytext,'$END');
                elsif yytext in ('ELSE','END') then
                    yytext := '/*#'||yytext||'*/';
                    plib.parse_command(yytext);
                else
					lset;
					if put then return(ID_); end if;
                end if;
            
elsif nstr = 30 then
  
                  if flag=5 then
                    flag:= 0;
                  else
                    if yytext='"CONSTANT"' then yytext:='CONSTANT'; end if;
					lset;
					if put then return(ID_); end if;
                  end if;
				
elsif nstr = 31 then
        
				lset; flag := -1;
				if put then return(ascii('.')); end if;
			
elsif nstr = 32 then
 null; 
elsif nstr = 33 then
          
				lset;
				if put then return(ascii(yytext)); end if;
			
		elsif nstr = -1 then
			exit;
		else
			yyoutput('bad switch yylook ' || nstr );
		end if;
	end loop;
	return(0);
end yylex;
--
procedure error_value is
begin
     plib.plp_error( NULL, 'PARSER_ERROR', 'Character sequence is too long' );
end;
--
procedure lset is
begin
    put := plib.plp$parsedef;
    yylval.text:= yytext;
    yylval.line:= plib.plp$line;
	yylval.pos := plib.plp$pos - length(yytext);
    flag := 0;
exception when VALUE_ERROR then
    error_value;
end;
--
procedure lsetu is
begin
    put := plib.plp$parsedef;
    yylval.text:= upper(yytext);
    yylval.line:= plib.plp$line;
	yylval.pos := plib.plp$pos - length(yytext);
    flag := 0;
exception when VALUE_ERROR then
    error_value;
end;
--
procedure extractModificator is
begin
  yytext := lower(yytext);
  if toks.exists(yytext) then
    idx := toks(yytext);
    if idx is null then
      flag := 0;
    else
      lset;
      if fset.exists(idx) then
        flag := fset(idx);
      end if;
    end if;
  else
    yytext := substr(yytext,2);
    lsetu;
    idx := VARMETH_;
  end if;
end;
--
procedure extractToken is
begin
  if flag<0 then
    lsetu;
    idx := ID_;
    return;
  end if;
  yytext := lower(yytext);
  if toks.exists(yytext) then
    idx := toks(yytext);
    if idx in (BEGIN_, FUNCTION_, PROCEDURE_, TYPE_, DECLARE_) then
      if to_change_level then
        plib.change_declare_level();
      end if;
    elsif idx = PUBLIC_ then
      yytext := upper(yytext);
    end if;
    if idx>0 then
      lset;
      if fset.exists(idx) then
        flag := fset(idx);
      end if;
    else
      idx := -idx;
      if fset.exists(idx) then
        if flag = idx then
          flag := fset(idx);
          if flag < 256 then
            idx := null;
          else
            idx := flag;
            lset;
          end if;
        elsif flag=5 then
          flag:= 0;
          idx := null;
        elsif flag=13 and idx=0 then
          flag := fset(idx);
          idx := null;
        else
          lsetu;
          idx := ID_;
        end if;
      elsif idx = BY_ then
        if flag=6 then
          yytext := 'siblings by';
        elsif flag=10 then
          yytext := 'by nocycle';
        end if;
        lset;
      elsif idx = CONSTANT_ then
        yytext := plib.input;
        plib.unput(yytext);
        if yytext='.' then
          yytext := 'CONSTANT';
          idx := ID_;
        else
          yytext := 'constant';
        end if;
        lset;
      elsif idx = LOB_ then
        if yytext in ('clob','nclob') then
          lset;
          flag := 3;
        else
          if yytext = 'urowid' then
            yytext := 'rowid';
          else
            yytext := 'clob';
          end if;
          lset;
        end if;
      elsif idx = FUNCTION_ then
        if flag = 12 then
     	  plib.get_comment(yytext,';');
          plib.unput(';');
          idx := null;
        else
          lsetu;
          idx := ID_;
        end if;
      else
        lset;
        idx := plib.time_interval(idx);
      end if;
    end if;
  elsif flag=5 then
    flag:= 0;
    idx := null;
  else
    lsetu;
    idx := ID_;
  end if;
end;
--
procedure LInit is
begin
  flag := 0; put := true;
  to_change_level := true;
  -- Tokens
  toks('type') := TYPE_;
  toks('ref') := REF_;
  toks('number') := NUMBER_;
  toks('integer') := INTEGER_;
  toks('date') := DATE_;
  toks('boolean') := BOOLEAN_;
  toks('string') := STRING_; fset(STRING_) := 3;
  toks('and') := AND_;
  toks('or') := OR_;
  toks('not') := NOT_;
  toks('null') := NULL_;
  toks('nan') := NULL_;
--toks('infinite') := NULL_;  -- PLATFORM-4933, BS00900624
  toks('declare') := DECLARE_;
  toks('begin') := BEGIN_;
  toks('exception') := EXCEPTION_;
  toks('end') := END_;
  toks('when') := WHEN_;
  toks('true') := BOOLEAN_CONST_;
  toks('false') := BOOLEAN_CONST_;
  toks('if') := IF_;
  toks('then') := THEN_;
  toks('elsif') := ELSIF_;
  toks('else') := ELSE_;
  toks('in') := IN_;
  toks('out') := OUT_; fset(OUT_) := 2;
  toks('loop') := LOOP_;
  toks('while') := WHILE_;
  toks('for') := FOR_; fset(FOR_) := 100;
  toks('exit') := EXIT_;
  toks('locate') := LOCATE_; fset(LOCATE_) := 100;
  toks('exact') := EXACT_;
  toks('where') := WHERE_;
  toks('insert') := INSERT_; fset(INSERT_) := 100;
  toks('into') := INTO_;
  toks('procedure') := PROCEDURE_;
  toks('function') := FUNCTION_;
  toks('record') := RECORD_;
  toks('table') := TABLE_;
  toks('multiset') := TABLE_;
  toks('of') := OF_;
  toks('is') := IS_; fset(IS_) := 12;
  toks('as') := IS_;
  toks('goto') := GOTO_;
  toks('raise') := RAISE_;
  toks('return') := RETURN_;
  toks('returning') := RETURN_;
  toks('others') := OTHERS_;
  toks('order') := ORDER_; fset(ORDER_) := 1;
  toks('by') := -BY_;
  toks('asc') := ASC_; fset(ASC_) := 7;
  toks('desc') := DESC_; fset(DESC_) := 7;
  toks('lock') := LOCK_;
  toks('nowait') := NOWAIT_;
  toks('wait') := WAIT_;
  toks('like') := LIKE_;
  toks('select') := SELECT_; fset(SELECT_) := 100;
  toks('update') := UPDATE_; fset(UPDATE_) := 100;
  toks('group') := GROUP_;
  toks('having') := HAVING_;
  toks('connect') := CONNECT_; fset(CONNECT_):= 9;
  toks('start') := START_;
  toks('prior') := PRIOR_;
  toks('exists') := EXISTS_;
  toks('escape') := ESCAPE_;
  toks('any') := ANY_;
  toks('union') := UNION_;
  toks('minus') := MINUS_;
  toks('intersect') := INTERSECT_;
  toks('reverse') := REVERSE_;
  toks('savepoint') := SAVEPOINT_;
  toks('rollback') := ROLLBACK_;
  toks('to') := TO_;
  toks('commit') := COMMIT_;
  toks('pragma') := PRAGMA_;
  toks('default') := DEFAULT_;
  toks('all') := ALL_;
  toks('collections') := COLL_;
  toks('one') := ONE_;
  toks('cursor') := CURSOR_;
  toks('const') := -CONSTANT_;
  toks('constant') := -CONSTANT_;
  toks('varchar') := STRING_;
  toks('varchar2') := STRING_;
  toks('nstring') := NSTRING_;
  toks('nvarchar2') := NSTRING_;
  toks('distinct') := DISTINCT_;
  toks('var') := VAR_;
  toks('index') := INDEX_;
  toks('char') := STRING_;
  toks('byte') := -13; fset(13) := STRING_;
  toks('binary_integer') := INTEGER_;
  toks('pls_integer') := INTEGER_;
  toks('parallel_enable') := FUNCPROP_;
  toks('connect_by_root') := PRIOR_;
  toks('subtype') := TYPE_;
  toks('natural') := INTEGER_;
  toks('case') := CASE_;
  toks('continue') := CONTINUE_;
  toks('deterministic') := FUNCPROP_;
  toks('pipelined'):= FUNCPROP_;
  toks('result_cache'):= FUNCPROP_;
  toks('nostatic') := NOSTATIC_;
  toks('raw') := RAW_;
  toks('long') := LONG_;
  toks('delete') := DELETE_; fset(DELETE_) := 100;
  toks('rowid') := LOB_;
  toks('blob') := LOB_;
  toks('clob') := -LOB_;
  toks('nclob') := -LOB_;
  toks('urowid') := -LOB_;
  toks('bfile') := LOB_;
  toks('timestamp') := -TIMESTAMP_;
  toks('interval') := -INTERVAL_;
  toks('varray') := VARRAY_;
  toks('exceptionloop') := LOOP_;
  toks('using') := NUMLOW_;
  toks('immediate') := NUMHIGH_;
  toks('language') := -FUNCTION_;
  toks('public') := PUBLIC_;
  toks('siblings') := -1; fset(1) := 6;
  toks('nocopy') := -2; fset(2) := 0;
  toks('character') := -3; fset(3) := 4;
  toks('set') := -4; fset(4) := 5;
  toks('nulls') := -7; fset(7) := 8;
  toks('first') := -8; fset(8) := RELATIONAL_;
  toks('last') := -8;
  toks('nocycle') := -9; fset(9) := 10;
  toks('bulk') := 0; fset(0) := 11;
  toks('collect') := -11; fset(11) := 0;
  -- Modifiers
  toks('%id') := obj_id_;
  toks('%class') := obj_class_;
  toks('%classname') := obj_class_;
  toks('%state') := obj_state_;
  toks('%statename') := obj_state_;
  toks('%collection') := obj_collection_;
  toks('%type') := obj_type_;
  toks('%parent') := obj_parent_;
  toks('%entity') := obj_class_entity_;
  toks('%classparent') := obj_class_parent_;
  toks('%parentclass') := DBCLASS_;
  toks('%locate') := BLOCK_; fset(BLOCK_) := 100;
  toks('%insert') := UNKNOWN_;
  toks('%init') := obj_init_;
  toks('%attrs') := obj_init_;
  toks('%lock') := RTL_;
  toks('%size') := SOS_;
  toks('%rowid') := ROWID_;
  toks('%delete') := METHOD_;
  toks('%log') := METHOD_;
  toks('%check') := METHOD_;
  toks('%key') := ATTR_;
  toks('%orascn') := ATTR_;
  toks('%request'):= ATTR_;
  toks('%scn') := ATTR_;
  toks('%ses') := ATTR_;
  toks('%value') := ATTR_;
  toks('%arch') := SOS_;
  toks('%compare') := SOS_;
  toks('%open') := MODIFIER_;
  toks('%getcollection') := COLLECTION_;
  toks('%access_obj') := MEMO_;
  toks('%access_ref') := MEMO_;
  toks('%charset') := null;
  toks('%rowtype') := VARMETH_;
  toks('%object') := VARMETH_;
  toks('%rowtable') := VARMETH_;
end;
-- don't remove this line


procedure Init is
begin LInit;
vs(0):=0;

vs(1):=33;
vs(2):=0;

vs(3):=32;
vs(4):=33;
vs(5):=0;

vs(6):=32;
vs(7):=0;

vs(8):=33;
vs(9):=0;

vs(10):=33;
vs(11):=0;

vs(12):=33;
vs(13):=0;

vs(14):=33;
vs(15):=0;

vs(16):=33;
vs(17):=0;

vs(18):=3;
vs(19):=33;
vs(20):=0;

vs(21):=33;
vs(22):=0;

vs(23):=33;
vs(24):=0;

vs(25):=31;
vs(26):=33;
vs(27):=0;

vs(28):=33;
vs(29):=0;

vs(30):=6;
vs(31):=7;
vs(32):=33;
vs(33):=0;

vs(34):=33;
vs(35):=0;

vs(36):=33;
vs(37):=0;

vs(38):=33;
vs(39):=0;

vs(40):=33;
vs(41):=0;

vs(42):=1;
vs(43):=33;
vs(44):=0;

vs(45):=4;
vs(46):=33;
vs(47):=0;

vs(48):=5;
vs(49):=33;
vs(50):=0;

vs(51):=33;
vs(52):=0;

vs(53):=33;
vs(54):=0;

vs(55):=10;
vs(56):=0;

vs(57):=29;
vs(58):=0;

vs(59):=2;
vs(60):=0;

vs(61):=24;
vs(62):=0;

vs(63):=23;
vs(64):=0;

vs(65):=26;
vs(66):=0;

vs(67):=20;
vs(68):=0;

vs(69):=16;
vs(70):=0;

vs(71):=7;
vs(72):=0;

vs(73):=27;
vs(74):=0;

vs(75):=6;
vs(76):=7;
vs(77):=0;

vs(78):=7;
vs(79):=0;

vs(80):=17;
vs(81):=0;

vs(82):=8;
vs(83):=0;

vs(84):=14;
vs(85):=0;

vs(86):=13;
vs(87):=0;

vs(88):=11;
vs(89):=0;

vs(90):=22;
vs(91):=0;

vs(92):=21;
vs(93):=0;

vs(94):=12;
vs(95):=0;

vs(96):=15;
vs(97):=0;

vs(98):=1;
vs(99):=0;

vs(100):=9;
vs(101):=0;

vs(102):=28;
vs(103):=0;

vs(104):=30;
vs(105):=0;

vs(106):=18;
vs(107):=0;

vs(108):=19;
vs(109):=0;

vs(110):=7;
vs(111):=0;

vs(112):=25;
vs(113):=0;
vs(114):=0;
v(0):=0;a(0):=0;	v(1):=0;a(1):=0;	v(2):=1;a(2):=3;	v(3):=0;a(3):=0;	
v(4):=0;a(4):=0;	v(5):=0;a(5):=0;	v(6):=0;a(6):=0;	v(7):=0;a(7):=0;	
v(8):=0;a(8):=0;	v(9):=0;a(9):=0;	v(10):=1;a(10):=4;	v(11):=1;a(11):=5;	
v(12):=0;a(12):=0;	v(13):=0;a(13):=0;	v(14):=0;a(14):=0;	v(15):=0;a(15):=0;	
v(16):=0;a(16):=0;	v(17):=0;a(17):=0;	v(18):=4;a(18):=5;	v(19):=4;a(19):=5;	
v(20):=7;a(20):=27;	v(21):=0;a(21):=0;	v(22):=4;a(22):=5;	v(23):=0;a(23):=0;	
v(24):=0;a(24):=0;	v(25):=0;a(25):=0;	v(26):=0;a(26):=0;	v(27):=0;a(27):=0;	
v(28):=7;a(28):=27;	v(29):=7;a(29):=27;	v(30):=0;a(30):=0;	v(31):=0;a(31):=0;	
v(32):=0;a(32):=0;	v(33):=0;a(33):=0;	v(34):=1;a(34):=6;	v(35):=1;a(35):=7;	
v(36):=1;a(36):=3;	v(37):=1;a(37):=8;	v(38):=1;a(38):=9;	v(39):=1;a(39):=10;	
v(40):=1;a(40):=11;	v(41):=4;a(41):=5;	v(42):=27;a(42):=55;	v(43):=1;a(43):=12;	
v(44):=34;a(44):=58;	v(45):=65;a(45):=66;	v(46):=1;a(46):=13;	v(47):=1;a(47):=14;	
v(48):=1;a(48):=15;	v(49):=1;a(49):=16;	v(50):=12;a(50):=33;	v(51):=15;a(51):=38;	
v(52):=68;a(52):=69;	v(53):=7;a(53):=0;	v(54):=7;a(54):=27;	v(55):=0;a(55):=0;	
v(56):=0;a(56):=0;	v(57):=0;a(57):=0;	v(58):=13;a(58):=34;	v(59):=1;a(59):=17;	
v(60):=0;a(60):=0;	v(61):=1;a(61):=18;	v(62):=1;a(62):=19;	v(63):=1;a(63):=20;	
v(64):=6;a(64):=26;	v(65):=0;a(65):=0;	v(66):=1;a(66):=21;	v(67):=7;a(67):=27;	
v(68):=2;a(68):=6;	v(69):=1;a(69):=21;	v(70):=1;a(70):=21;	v(71):=2;a(71):=8;	
v(72):=2;a(72):=9;	v(73):=2;a(73):=10;	v(74):=2;a(74):=11;	v(75):=13;a(75):=35;	
v(76):=17;a(76):=43;	v(77):=2;a(77):=12;	v(78):=29;a(78):=56;	v(79):=17;a(79):=44;	
v(80):=2;a(80):=13;	v(81):=2;a(81):=14;	v(82):=2;a(82):=15;	v(83):=30;a(83):=57;	
v(84):=7;a(84):=27;	v(85):=19;a(85):=48;	v(86):=19;a(86):=49;	v(87):=7;a(87):=27;	
v(88):=7;a(88):=27;	v(89):=18;a(89):=45;	v(90):=18;a(90):=46;	v(91):=18;a(91):=47;	
v(92):=1;a(92):=22;	v(93):=2;a(93):=17;	v(94):=0;a(94):=0;	v(95):=2;a(95):=18;	
v(96):=2;a(96):=19;	v(97):=2;a(97):=20;	v(98):=8;a(98):=28;	v(99):=8;a(99):=28;	
v(100):=8;a(100):=28;	v(101):=8;a(101):=28;	v(102):=8;a(102):=28;	v(103):=8;a(103):=28;	
v(104):=8;a(104):=28;	v(105):=8;a(105):=28;	v(106):=8;a(106):=28;	v(107):=8;a(107):=28;	
v(108):=8;a(108):=28;	v(109):=8;a(109):=28;	v(110):=8;a(110):=28;	v(111):=8;a(111):=28;	
v(112):=8;a(112):=28;	v(113):=8;a(113):=28;	v(114):=8;a(114):=28;	v(115):=8;a(115):=28;	
v(116):=8;a(116):=28;	v(117):=8;a(117):=28;	v(118):=8;a(118):=28;	v(119):=8;a(119):=28;	
v(120):=8;a(120):=28;	v(121):=8;a(121):=28;	v(122):=8;a(122):=28;	v(123):=8;a(123):=28;	
v(124):=1;a(124):=23;	v(125):=1;a(125):=24;	v(126):=2;a(126):=22;	v(127):=1;a(127):=25;	
v(128):=20;a(128):=50;	v(129):=20;a(129):=51;	v(130):=8;a(130):=28;	v(131):=8;a(131):=28;	
v(132):=8;a(132):=28;	v(133):=8;a(133):=28;	v(134):=8;a(134):=28;	v(135):=8;a(135):=28;	
v(136):=8;a(136):=28;	v(137):=8;a(137):=28;	v(138):=8;a(138):=28;	v(139):=8;a(139):=28;	
v(140):=8;a(140):=28;	v(141):=8;a(141):=28;	v(142):=8;a(142):=28;	v(143):=8;a(143):=28;	
v(144):=8;a(144):=28;	v(145):=8;a(145):=28;	v(146):=8;a(146):=28;	v(147):=8;a(147):=28;	
v(148):=8;a(148):=28;	v(149):=8;a(149):=28;	v(150):=8;a(150):=28;	v(151):=8;a(151):=28;	
v(152):=8;a(152):=28;	v(153):=8;a(153):=28;	v(154):=8;a(154):=28;	v(155):=8;a(155):=28;	
v(156):=9;a(156):=29;	v(157):=24;a(157):=53;	v(158):=2;a(158):=23;	v(159):=2;a(159):=24;	
v(160):=14;a(160):=36;	v(161):=2;a(161):=25;	v(162):=14;a(162):=37;	v(163):=14;a(163):=37;	
v(164):=14;a(164):=37;	v(165):=14;a(165):=37;	v(166):=14;a(166):=37;	v(167):=14;a(167):=37;	
v(168):=14;a(168):=37;	v(169):=14;a(169):=37;	v(170):=14;a(170):=37;	v(171):=14;a(171):=37;	
v(172):=9;a(172):=30;	v(173):=58;a(173):=61;	v(174):=61;a(174):=62;	v(175):=62;a(175):=63;	
v(176):=9;a(176):=31;	v(177):=9;a(177):=31;	v(178):=9;a(178):=31;	v(179):=9;a(179):=31;	
v(180):=9;a(180):=31;	v(181):=9;a(181):=31;	v(182):=9;a(182):=31;	v(183):=9;a(183):=31;	
v(184):=9;a(184):=31;	v(185):=9;a(185):=31;	v(186):=9;a(186):=31;	v(187):=9;a(187):=31;	
v(188):=9;a(188):=31;	v(189):=9;a(189):=31;	v(190):=9;a(190):=31;	v(191):=9;a(191):=31;	
v(192):=9;a(192):=31;	v(193):=9;a(193):=31;	v(194):=9;a(194):=31;	v(195):=9;a(195):=31;	
v(196):=9;a(196):=31;	v(197):=9;a(197):=31;	v(198):=9;a(198):=31;	v(199):=9;a(199):=31;	
v(200):=9;a(200):=31;	v(201):=9;a(201):=31;	v(202):=63;a(202):=64;	v(203):=64;a(203):=65;	
v(204):=66;a(204):=67;	v(205):=67;a(205):=68;	v(206):=69;a(206):=70;	v(207):=70;a(207):=71;	
v(208):=9;a(208):=31;	v(209):=9;a(209):=31;	v(210):=9;a(210):=31;	v(211):=9;a(211):=31;	
v(212):=9;a(212):=31;	v(213):=9;a(213):=31;	v(214):=9;a(214):=31;	v(215):=9;a(215):=31;	
v(216):=9;a(216):=31;	v(217):=9;a(217):=31;	v(218):=9;a(218):=31;	v(219):=9;a(219):=31;	
v(220):=9;a(220):=31;	v(221):=9;a(221):=31;	v(222):=9;a(222):=31;	v(223):=9;a(223):=31;	
v(224):=9;a(224):=31;	v(225):=9;a(225):=31;	v(226):=9;a(226):=31;	v(227):=9;a(227):=31;	
v(228):=9;a(228):=31;	v(229):=9;a(229):=31;	v(230):=9;a(230):=31;	v(231):=9;a(231):=31;	
v(232):=9;a(232):=31;	v(233):=9;a(233):=31;	v(234):=10;a(234):=32;	v(235):=10;a(235):=32;	
v(236):=10;a(236):=32;	v(237):=10;a(237):=32;	v(238):=10;a(238):=32;	v(239):=10;a(239):=32;	
v(240):=10;a(240):=32;	v(241):=10;a(241):=32;	v(242):=10;a(242):=32;	v(243):=10;a(243):=32;	
v(244):=10;a(244):=32;	v(245):=10;a(245):=32;	v(246):=10;a(246):=32;	v(247):=10;a(247):=32;	
v(248):=10;a(248):=32;	v(249):=10;a(249):=32;	v(250):=10;a(250):=32;	v(251):=10;a(251):=32;	
v(252):=10;a(252):=32;	v(253):=10;a(253):=32;	v(254):=10;a(254):=32;	v(255):=10;a(255):=32;	
v(256):=10;a(256):=32;	v(257):=10;a(257):=32;	v(258):=10;a(258):=32;	v(259):=10;a(259):=32;	
v(260):=71;a(260):=72;	v(261):=0;a(261):=0;	v(262):=0;a(262):=0;	v(263):=0;a(263):=0;	
v(264):=0;a(264):=0;	v(265):=0;a(265):=0;	v(266):=10;a(266):=32;	v(267):=10;a(267):=32;	
v(268):=10;a(268):=32;	v(269):=10;a(269):=32;	v(270):=10;a(270):=32;	v(271):=10;a(271):=32;	
v(272):=10;a(272):=32;	v(273):=10;a(273):=32;	v(274):=10;a(274):=32;	v(275):=10;a(275):=32;	
v(276):=10;a(276):=32;	v(277):=10;a(277):=32;	v(278):=10;a(278):=32;	v(279):=10;a(279):=32;	
v(280):=10;a(280):=32;	v(281):=10;a(281):=32;	v(282):=10;a(282):=32;	v(283):=10;a(283):=32;	
v(284):=10;a(284):=32;	v(285):=10;a(285):=32;	v(286):=10;a(286):=32;	v(287):=10;a(287):=32;	
v(288):=10;a(288):=32;	v(289):=10;a(289):=32;	v(290):=10;a(290):=32;	v(291):=10;a(291):=32;	
v(292):=16;a(292):=39;	v(293):=0;a(293):=0;	v(294):=16;a(294):=40;	v(295):=16;a(295):=40;	
v(296):=16;a(296):=40;	v(297):=16;a(297):=40;	v(298):=16;a(298):=40;	v(299):=16;a(299):=40;	
v(300):=16;a(300):=40;	v(301):=16;a(301):=40;	v(302):=16;a(302):=40;	v(303):=16;a(303):=40;	
v(304):=39;a(304):=37;	v(305):=39;a(305):=37;	v(306):=39;a(306):=37;	v(307):=39;a(307):=37;	
v(308):=39;a(308):=37;	v(309):=39;a(309):=37;	v(310):=39;a(310):=37;	v(311):=39;a(311):=37;	
v(312):=39;a(312):=37;	v(313):=39;a(313):=37;	v(314):=16;a(314):=41;	v(315):=16;a(315):=42;	
v(316):=16;a(316):=41;	v(317):=0;a(317):=0;	v(318):=0;a(318):=0;	v(319):=21;a(319):=52;	
v(320):=21;a(320):=52;	v(321):=59;a(321):=60;	v(322):=59;a(322):=60;	v(323):=59;a(323):=60;	
v(324):=59;a(324):=60;	v(325):=59;a(325):=60;	v(326):=59;a(326):=60;	v(327):=59;a(327):=60;	
v(328):=59;a(328):=60;	v(329):=59;a(329):=60;	v(330):=59;a(330):=60;	v(331):=0;a(331):=0;	
v(332):=21;a(332):=52;	v(333):=21;a(333):=52;	v(334):=21;a(334):=52;	v(335):=21;a(335):=52;	
v(336):=21;a(336):=52;	v(337):=21;a(337):=52;	v(338):=21;a(338):=52;	v(339):=21;a(339):=52;	
v(340):=21;a(340):=52;	v(341):=21;a(341):=52;	v(342):=0;a(342):=0;	v(343):=60;a(343):=41;	
v(344):=0;a(344):=0;	v(345):=60;a(345):=41;	v(346):=16;a(346):=41;	v(347):=16;a(347):=42;	
v(348):=16;a(348):=41;	v(349):=21;a(349):=52;	v(350):=21;a(350):=52;	v(351):=21;a(351):=52;	
v(352):=21;a(352):=52;	v(353):=21;a(353):=52;	v(354):=21;a(354):=52;	v(355):=21;a(355):=52;	
v(356):=21;a(356):=52;	v(357):=21;a(357):=52;	v(358):=21;a(358):=52;	v(359):=21;a(359):=52;	
v(360):=21;a(360):=52;	v(361):=21;a(361):=52;	v(362):=21;a(362):=52;	v(363):=21;a(363):=52;	
v(364):=21;a(364):=52;	v(365):=21;a(365):=52;	v(366):=21;a(366):=52;	v(367):=21;a(367):=52;	
v(368):=21;a(368):=52;	v(369):=21;a(369):=52;	v(370):=21;a(370):=52;	v(371):=21;a(371):=52;	
v(372):=21;a(372):=52;	v(373):=21;a(373):=52;	v(374):=21;a(374):=52;	v(375):=60;a(375):=41;	
v(376):=0;a(376):=0;	v(377):=60;a(377):=41;	v(378):=0;a(378):=0;	v(379):=21;a(379):=52;	
v(380):=0;a(380):=0;	v(381):=21;a(381):=52;	v(382):=21;a(382):=52;	v(383):=21;a(383):=52;	
v(384):=21;a(384):=52;	v(385):=21;a(385):=52;	v(386):=21;a(386):=52;	v(387):=21;a(387):=52;	
v(388):=21;a(388):=52;	v(389):=21;a(389):=52;	v(390):=21;a(390):=52;	v(391):=21;a(391):=52;	
v(392):=21;a(392):=52;	v(393):=21;a(393):=52;	v(394):=21;a(394):=52;	v(395):=21;a(395):=52;	
v(396):=21;a(396):=52;	v(397):=21;a(397):=52;	v(398):=21;a(398):=52;	v(399):=21;a(399):=52;	
v(400):=21;a(400):=52;	v(401):=21;a(401):=52;	v(402):=21;a(402):=52;	v(403):=21;a(403):=52;	
v(404):=21;a(404):=52;	v(405):=21;a(405):=52;	v(406):=21;a(406):=52;	v(407):=25;a(407):=54;	
v(408):=25;a(408):=54;	v(409):=25;a(409):=54;	v(410):=25;a(410):=54;	v(411):=25;a(411):=54;	
v(412):=25;a(412):=54;	v(413):=25;a(413):=54;	v(414):=25;a(414):=54;	v(415):=25;a(415):=54;	
v(416):=25;a(416):=54;	v(417):=25;a(417):=54;	v(418):=25;a(418):=54;	v(419):=25;a(419):=54;	
v(420):=25;a(420):=54;	v(421):=25;a(421):=54;	v(422):=25;a(422):=54;	v(423):=25;a(423):=54;	
v(424):=25;a(424):=54;	v(425):=25;a(425):=54;	v(426):=25;a(426):=54;	v(427):=25;a(427):=54;	
v(428):=25;a(428):=54;	v(429):=25;a(429):=54;	v(430):=25;a(430):=54;	v(431):=25;a(431):=54;	
v(432):=25;a(432):=54;	v(433):=0;a(433):=0;	v(434):=0;a(434):=0;	v(435):=0;a(435):=0;	
v(436):=0;a(436):=0;	v(437):=0;a(437):=0;	v(438):=0;a(438):=0;	v(439):=25;a(439):=54;	
v(440):=25;a(440):=54;	v(441):=25;a(441):=54;	v(442):=25;a(442):=54;	v(443):=25;a(443):=54;	
v(444):=25;a(444):=54;	v(445):=25;a(445):=54;	v(446):=25;a(446):=54;	v(447):=25;a(447):=54;	
v(448):=25;a(448):=54;	v(449):=25;a(449):=54;	v(450):=25;a(450):=54;	v(451):=25;a(451):=54;	
v(452):=25;a(452):=54;	v(453):=25;a(453):=54;	v(454):=25;a(454):=54;	v(455):=25;a(455):=54;	
v(456):=25;a(456):=54;	v(457):=25;a(457):=54;	v(458):=25;a(458):=54;	v(459):=25;a(459):=54;	
v(460):=25;a(460):=54;	v(461):=25;a(461):=54;	v(462):=25;a(462):=54;	v(463):=25;a(463):=54;	
v(464):=25;a(464):=54;	v(465):=31;a(465):=31;	v(466):=31;a(466):=31;	v(467):=0;a(467):=0;	
v(468):=0;a(468):=0;	v(469):=0;a(469):=0;	v(470):=0;a(470):=0;	v(471):=0;a(471):=0;	
v(472):=0;a(472):=0;	v(473):=0;a(473):=0;	v(474):=0;a(474):=0;	v(475):=0;a(475):=0;	
v(476):=0;a(476):=0;	v(477):=0;a(477):=0;	v(478):=31;a(478):=31;	v(479):=31;a(479):=31;	
v(480):=31;a(480):=31;	v(481):=31;a(481):=31;	v(482):=31;a(482):=31;	v(483):=31;a(483):=31;	
v(484):=31;a(484):=31;	v(485):=31;a(485):=31;	v(486):=31;a(486):=31;	v(487):=31;a(487):=31;	
v(488):=0;a(488):=0;	v(489):=0;a(489):=0;	v(490):=0;a(490):=0;	v(491):=0;a(491):=0;	
v(492):=0;a(492):=0;	v(493):=0;a(493):=0;	v(494):=0;a(494):=0;	v(495):=31;a(495):=31;	
v(496):=31;a(496):=31;	v(497):=31;a(497):=31;	v(498):=31;a(498):=31;	v(499):=31;a(499):=31;	
v(500):=31;a(500):=31;	v(501):=31;a(501):=31;	v(502):=31;a(502):=31;	v(503):=31;a(503):=31;	
v(504):=31;a(504):=31;	v(505):=31;a(505):=31;	v(506):=31;a(506):=31;	v(507):=31;a(507):=31;	
v(508):=31;a(508):=31;	v(509):=31;a(509):=31;	v(510):=31;a(510):=31;	v(511):=31;a(511):=31;	
v(512):=31;a(512):=31;	v(513):=31;a(513):=31;	v(514):=31;a(514):=31;	v(515):=31;a(515):=31;	
v(516):=31;a(516):=31;	v(517):=31;a(517):=31;	v(518):=31;a(518):=31;	v(519):=31;a(519):=31;	
v(520):=31;a(520):=31;	v(521):=0;a(521):=0;	v(522):=0;a(522):=0;	v(523):=0;a(523):=0;	
v(524):=0;a(524):=0;	v(525):=31;a(525):=31;	v(526):=0;a(526):=0;	v(527):=31;a(527):=31;	
v(528):=31;a(528):=31;	v(529):=31;a(529):=31;	v(530):=31;a(530):=31;	v(531):=31;a(531):=31;	
v(532):=31;a(532):=31;	v(533):=31;a(533):=31;	v(534):=31;a(534):=31;	v(535):=31;a(535):=31;	
v(536):=31;a(536):=31;	v(537):=31;a(537):=31;	v(538):=31;a(538):=31;	v(539):=31;a(539):=31;	
v(540):=31;a(540):=31;	v(541):=31;a(541):=31;	v(542):=31;a(542):=31;	v(543):=31;a(543):=31;	
v(544):=31;a(544):=31;	v(545):=31;a(545):=31;	v(546):=31;a(546):=31;	v(547):=31;a(547):=31;	
v(548):=31;a(548):=31;	v(549):=31;a(549):=31;	v(550):=31;a(550):=31;	v(551):=31;a(551):=31;	
v(552):=31;a(552):=31;	v(553):=32;a(553):=32;	v(554):=32;a(554):=32;	v(555):=0;a(555):=0;	
v(556):=37;a(556):=37;	v(557):=37;a(557):=37;	v(558):=37;a(558):=37;	v(559):=37;a(559):=37;	
v(560):=37;a(560):=37;	v(561):=37;a(561):=37;	v(562):=37;a(562):=37;	v(563):=37;a(563):=37;	
v(564):=37;a(564):=37;	v(565):=37;a(565):=37;	v(566):=32;a(566):=32;	v(567):=32;a(567):=32;	
v(568):=32;a(568):=32;	v(569):=32;a(569):=32;	v(570):=32;a(570):=32;	v(571):=32;a(571):=32;	
v(572):=32;a(572):=32;	v(573):=32;a(573):=32;	v(574):=32;a(574):=32;	v(575):=32;a(575):=32;	
v(576):=37;a(576):=41;	v(577):=37;a(577):=42;	v(578):=37;a(578):=41;	v(579):=42;a(579):=59;	
v(580):=0;a(580):=0;	v(581):=42;a(581):=59;	v(582):=54;a(582):=54;	v(583):=54;a(583):=54;	
v(584):=42;a(584):=60;	v(585):=42;a(585):=60;	v(586):=42;a(586):=60;	v(587):=42;a(587):=60;	
v(588):=42;a(588):=60;	v(589):=42;a(589):=60;	v(590):=42;a(590):=60;	v(591):=42;a(591):=60;	
v(592):=42;a(592):=60;	v(593):=42;a(593):=60;	v(594):=0;a(594):=0;	v(595):=54;a(595):=54;	
v(596):=54;a(596):=54;	v(597):=54;a(597):=54;	v(598):=54;a(598):=54;	v(599):=54;a(599):=54;	
v(600):=54;a(600):=54;	v(601):=54;a(601):=54;	v(602):=54;a(602):=54;	v(603):=54;a(603):=54;	
v(604):=54;a(604):=54;	v(605):=0;a(605):=0;	v(606):=0;a(606):=0;	v(607):=0;a(607):=0;	
v(608):=37;a(608):=41;	v(609):=37;a(609):=42;	v(610):=37;a(610):=41;	v(611):=0;a(611):=0;	
v(612):=0;a(612):=0;	v(613):=32;a(613):=32;	v(614):=0;a(614):=0;	v(615):=0;a(615):=0;	
v(616):=0;a(616):=0;	v(617):=0;a(617):=0;	v(618):=0;a(618):=0;	v(619):=0;a(619):=0;	
v(620):=0;a(620):=0;	v(621):=0;a(621):=0;	v(622):=0;a(622):=0;	v(623):=0;a(623):=0;	
v(624):=0;a(624):=0;	v(625):=0;a(625):=0;	v(626):=0;a(626):=0;	v(627):=0;a(627):=0;	
v(628):=0;a(628):=0;	v(629):=0;a(629):=0;	v(630):=0;a(630):=0;	v(631):=0;a(631):=0;	
v(632):=0;a(632):=0;	v(633):=0;a(633):=0;	v(634):=0;a(634):=0;	v(635):=0;a(635):=0;	
v(636):=0;a(636):=0;	v(637):=0;a(637):=0;	v(638):=0;a(638):=0;	v(639):=0;a(639):=0;	
v(640):=0;a(640):=0;	v(641):=0;a(641):=0;	v(642):=54;a(642):=54;	v(643):=0;a(643):=0;	
v(644):=0;a(644):=0;
f(0):=0;o(0):=0;s(0):=0;
f(1):=-1;o(1):=0;s(1):=0;
f(2):=-35;o(2):=1;s(2):=0;
f(3):=0;o(3):=0;s(3):=1;
f(4):=9;o(4):=0;s(4):=3;
f(5):=0;o(5):=4;s(5):=6;
f(6):=3;o(6):=0;s(6):=8;
f(7):=-19;o(7):=0;s(7):=10;
f(8):=33;o(8):=0;s(8):=12;
f(9):=111;o(9):=0;s(9):=14;
f(10):=169;o(10):=0;s(10):=16;
f(11):=0;o(11):=0;s(11):=18;
f(12):=8;o(12):=0;s(12):=21;
f(13):=13;o(13):=0;s(13):=23;
f(14):=114;o(14):=0;s(14):=25;
f(15):=9;o(15):=0;s(15):=28;
f(16):=246;o(16):=0;s(16):=30;
f(17):=18;o(17):=0;s(17):=34;
f(18):=29;o(18):=0;s(18):=36;
f(19):=24;o(19):=0;s(19):=38;
f(20):=67;o(20):=0;s(20):=40;
f(21):=284;o(21):=0;s(21):=42;
f(22):=0;o(22):=0;s(22):=45;
f(23):=0;o(23):=0;s(23):=48;
f(24):=33;o(24):=0;s(24):=51;
f(25):=342;o(25):=0;s(25):=53;
f(26):=0;o(26):=0;s(26):=55;
f(27):=-8;o(27):=7;s(27):=0;
f(28):=0;o(28):=8;s(28):=57;
f(29):=16;o(29):=0;s(29):=0;
f(30):=21;o(30):=0;s(30):=0;
f(31):=430;o(31):=0;s(31):=59;
f(32):=518;o(32):=10;s(32):=61;
f(33):=0;o(33):=0;s(33):=63;
f(34):=12;o(34):=0;s(34):=65;
f(35):=0;o(35):=0;s(35):=67;
f(36):=0;o(36):=0;s(36):=69;
f(37):=508;o(37):=0;s(37):=71;
f(38):=0;o(38):=0;s(38):=73;
f(39):=256;o(39):=0;s(39):=0;
f(40):=0;o(40):=16;s(40):=75;
f(41):=0;o(41):=0;s(41):=78;
f(42):=536;o(42):=0;s(42):=0;
f(43):=0;o(43):=0;s(43):=80;
f(44):=0;o(44):=0;s(44):=82;
f(45):=0;o(45):=0;s(45):=84;
f(46):=0;o(46):=0;s(46):=86;
f(47):=0;o(47):=0;s(47):=88;
f(48):=0;o(48):=0;s(48):=90;
f(49):=0;o(49):=0;s(49):=92;
f(50):=0;o(50):=0;s(50):=94;
f(51):=0;o(51):=0;s(51):=96;
f(52):=0;o(52):=21;s(52):=98;
f(53):=0;o(53):=0;s(53):=100;
f(54):=547;o(54):=25;s(54):=102;
f(55):=0;o(55):=0;s(55):=104;
f(56):=0;o(56):=0;s(56):=106;
f(57):=0;o(57):=0;s(57):=108;
f(58):=75;o(58):=0;s(58):=0;
f(59):=273;o(59):=0;s(59):=0;
f(60):=275;o(60):=59;s(60):=110;
f(61):=73;o(61):=0;s(61):=0;
f(62):=72;o(62):=0;s(62):=0;
f(63):=97;o(63):=0;s(63):=0;
f(64):=93;o(64):=0;s(64):=0;
f(65):=13;o(65):=0;s(65):=0;
f(66):=92;o(66):=0;s(66):=0;
f(67):=97;o(67):=0;s(67):=0;
f(68):=5;o(68):=0;s(68):=0;
f(69):=91;o(69):=0;s(69):=0;
f(70):=94;o(70):=0;s(70):=0;
f(71):=152;o(71):=0;s(71):=0;
f(72):=0;o(72):=0;s(72):=112;
f(73):=0;o(73):=0;s(73):=0;
m(0):=0  ;m(1):=1  ;m(2):=1  ;m(3):=1  ;
m(4):=1  ;m(5):=1  ;m(6):=1  ;m(7):=1  ;
m(8):=1  ;m(9):=9  ;m(10):=10 ;m(11):=1  ;
m(12):=1  ;m(13):=9  ;m(14):=1  ;m(15):=1  ;
m(16):=1  ;m(17):=1  ;m(18):=1  ;m(19):=1  ;
m(20):=1  ;m(21):=1  ;m(22):=1  ;m(23):=1  ;
m(24):=1  ;m(25):=1  ;m(26):=1  ;m(27):=1  ;
m(28):=1  ;m(29):=1  ;m(30):=1  ;m(31):=1  ;
m(32):=9  ;m(33):=1  ;m(34):=34 ;m(35):=35 ;
m(36):=35 ;m(37):=1  ;m(38):=1  ;m(39):=1  ;
m(40):=1  ;m(41):=1  ;m(42):=1  ;m(43):=1  ;
m(44):=1  ;m(45):=1  ;m(46):=1  ;m(47):=1  ;
m(48):=48 ;m(49):=48 ;m(50):=48 ;m(51):=48 ;
m(52):=48 ;m(53):=48 ;m(54):=48 ;m(55):=48 ;
m(56):=48 ;m(57):=48 ;m(58):=1  ;m(59):=1  ;
m(60):=1  ;m(61):=1  ;m(62):=1  ;m(63):=1  ;
m(64):=1  ;m(65):=65 ;m(66):=65 ;m(67):=65 ;
m(68):=68 ;m(69):=69 ;m(70):=68 ;m(71):=65 ;
m(72):=65 ;m(73):=65 ;m(74):=65 ;m(75):=65 ;
m(76):=65 ;m(77):=65 ;m(78):=65 ;m(79):=65 ;
m(80):=65 ;m(81):=65 ;m(82):=65 ;m(83):=65 ;
m(84):=65 ;m(85):=65 ;m(86):=65 ;m(87):=65 ;
m(88):=65 ;m(89):=65 ;m(90):=65 ;m(91):=1  ;
m(92):=1  ;m(93):=1  ;m(94):=1  ;m(95):=35 ;
m(96):=1  ;m(97):=65 ;m(98):=65 ;m(99):=65 ;
m(100):=68 ;m(101):=69 ;m(102):=68 ;m(103):=65 ;
m(104):=65 ;m(105):=65 ;m(106):=65 ;m(107):=65 ;
m(108):=65 ;m(109):=65 ;m(110):=65 ;m(111):=65 ;
m(112):=65 ;m(113):=65 ;m(114):=65 ;m(115):=65 ;
m(116):=65 ;m(117):=65 ;m(118):=65 ;m(119):=65 ;
m(120):=65 ;m(121):=65 ;m(122):=65 ;m(123):=1  ;
m(124):=1  ;m(125):=1  ;m(126):=1  ;m(127):=1  ;
m(128):=1  ;m(129):=1  ;m(130):=1  ;m(131):=1  ;
m(132):=1  ;m(133):=1  ;m(134):=1  ;m(135):=1  ;
m(136):=1  ;m(137):=1  ;m(138):=1  ;m(139):=1  ;
m(140):=1  ;m(141):=1  ;m(142):=1  ;m(143):=1  ;
m(144):=1  ;m(145):=1  ;m(146):=1  ;m(147):=1  ;
m(148):=1  ;m(149):=1  ;m(150):=1  ;m(151):=1  ;
m(152):=1  ;m(153):=1  ;m(154):=1  ;m(155):=1  ;
m(156):=1  ;m(157):=1  ;m(158):=1  ;m(159):=1  ;
m(160):=1  ;m(161):=1  ;m(162):=1  ;m(163):=1  ;
m(164):=1  ;m(165):=1  ;m(166):=1  ;m(167):=1  ;
m(168):=1  ;m(169):=1  ;m(170):=1  ;m(171):=1  ;
m(172):=1  ;m(173):=1  ;m(174):=1  ;m(175):=1  ;
m(176):=1  ;m(177):=1  ;m(178):=1  ;m(179):=1  ;
m(180):=1  ;m(181):=1  ;m(182):=1  ;m(183):=1  ;
m(184):=1  ;m(185):=1  ;m(186):=1  ;m(187):=1  ;
m(188):=1  ;m(189):=1  ;m(190):=1  ;m(191):=1  ;
m(192):=1  ;m(193):=1  ;m(194):=1  ;m(195):=1  ;
m(196):=1  ;m(197):=1  ;m(198):=1  ;m(199):=1  ;
m(200):=1  ;m(201):=1  ;m(202):=1  ;m(203):=1  ;
m(204):=1  ;m(205):=1  ;m(206):=1  ;m(207):=1  ;
m(208):=1  ;m(209):=1  ;m(210):=1  ;m(211):=1  ;
m(212):=1  ;m(213):=1  ;m(214):=1  ;m(215):=1  ;
m(216):=1  ;m(217):=1  ;m(218):=1  ;m(219):=1  ;
m(220):=1  ;m(221):=1  ;m(222):=1  ;m(223):=1  ;
m(224):=1  ;m(225):=1  ;m(226):=1  ;m(227):=1  ;
m(228):=1  ;m(229):=1  ;m(230):=1  ;m(231):=1  ;
m(232):=1  ;m(233):=1  ;m(234):=1  ;m(235):=1  ;
m(236):=1  ;m(237):=1  ;m(238):=1  ;m(239):=1  ;
m(240):=1  ;m(241):=1  ;m(242):=1  ;m(243):=1  ;
m(244):=1  ;m(245):=1  ;m(246):=1  ;m(247):=1  ;
m(248):=1  ;m(249):=1  ;m(250):=1  ;m(251):=1  ;
m(252):=1  ;m(253):=1  ;m(254):=1  ;m(255):=1  ;
m(256):=0;
e(0):=0;e(1):=0;e(2):=0;e(3):=0;
e(4):=0;e(5):=0;e(6):=0;e(7):=0;
e(8):=0;e(9):=0;e(10):=0;e(11):=0;
e(12):=0;e(13):=0;e(14):=0;e(15):=0;
e(16):=0;e(17):=0;e(18):=0;e(19):=0;
e(20):=0;e(21):=0;e(22):=0;e(23):=0;
e(24):=0;e(25):=0;e(26):=0;e(27):=0;
e(28):=0;e(29):=0;e(30):=0;e(31):=0;
e(32):=0;e(33):=0;e(34):=0;e(35):=0;
e(36):=0;

end;

----------------------------------------------------------------------
procedure yyerror( err_msg varchar2 ) is
begin
	plib.plp_error( NULL, 'PARSER_ERROR', err_msg );
end yyerror;
--
procedure yyoutput ( msg varchar2 ) is
begin
    rtl.debug(msg,0);
end yyoutput;
----------------------------------------------------------------------
procedure dump_symbol ( sym IN YYSTYPE ) is
begin
	yyoutput(rpad('-', 20, '-'));
	yyoutput('node: ' || sym.node);
	yyoutput('text: ' || sym.text);
	yyoutput('line: ' || sym.line);
	yyoutput('pos:  ' || sym.pos);
	yyoutput(rpad('-', 20, '-'));
end dump_symbol;
--

begin
	init;

	for c in (select * from plp$parser_info) loop
		if c.array = 'yyact' then
			yyact(c.idx) := c.value;
		elsif c.array = 'yypact' then
			yypact(c.idx) := c.value;
		elsif c.array = 'yychk' then
			yychk(c.idx) := c.value;
		elsif c.array = 'yydef' then
			yydef(c.idx) := c.value;
		elsif c.array = 'yyr1' then
			yyr1(c.idx) := c.value;
		elsif c.array = 'yyr2' then
			yyr2(c.idx) := c.value;
		elsif c.array = 'yyexca' then
			yyexca(c.idx) := c.value;
		elsif c.array = 'yypgo' then
			yypgo(c.idx) := c.value;
		end if;
	end loop;


end;
/
show errors
