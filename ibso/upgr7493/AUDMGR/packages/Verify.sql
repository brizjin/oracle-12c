prompt VERIFY_FUNCTION
CREATE FUNCTION     VERIFY_FUNCTION   (username varchar2,
  password varchar2,
  old_password varchar2)
  RETURN boolean IS
/*
 *	$HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUDM/Verify.sql $
 *	$Revision: 15069 $
 *	$Date:: 2012-03-06 13:35:47 #$
 */
   n boolean;
   m integer;
   cnt integer;
   differ integer;
   isdigit boolean;
   ischar  boolean;
   ispunct boolean;
   digitarray varchar2(20);
   punctarray varchar2(25);
   badsymbols varchar2(25);
   chararray varchar2(152);
   cur_sym varchar2(5);
   cur_sym_revers varchar2(5);
   cur_sym1 varchar2(5);
   cur_sym_revers1 varchar2(5);
   cur_sym2 varchar2(5);
   cur_sym_revers2 varchar2(5);
   qwerty_arrayLo  varchar2(70);
   qwerty_array1Lo varchar2(70);
   cnt_sym  integer; -- —колько символов нельз€ ввести подр€д с клавиатуры
--
   PASSWORD_IS_EMPTY constant varchar2(100) := 'ѕароль не может быть пустым';
   PASSWORD_IS_NAME constant varchar2(100) := 'ѕароль, совпадающий с именем пользовател€, запрещен.';
   PASSWORD_IS_SHORT constant varchar2(100) := 'ƒлина парол€ должна быть не меньше 8 символов.';
   PASSWORD_IS_SIMPLE constant varchar2(100) := 'ѕростой пароль запрещен.';
   PASS_CONTAINS_BAD_CHARS constant varchar2(100) := 'ѕароль содержит недопустимые символы.';
   PASS_MUST_CONTAIN_DIGITS constant varchar2(100) := 'ѕароль должен содержать хот€ бы одну цифру.';
   PASS_MUST_CONTAIN_LETTERS constant varchar2(100) := 'ѕароль должен содержать хот€ бы одну букву.';
   PASS_MUST_CONTAIN_DELIMETERS constant varchar2(100) := 'ѕароль должен содержать хот€ бы один знак препинани€.';
   PASSES_MUST_DIFFER_IN_N_CHARS constant varchar2(100) := 'Ќовый пароль от старого должен отличатьс€ хот€ бы на %1 символа.';
   PASS_CONTAINS_N_REPEATED_CHARS constant varchar2(100) := '¬ пароле есть символ, который повторилс€ подр€д %1 раза, это запрещено.';
   PASS_CONTAINS_SIMP_COMBINATION constant varchar2(100) := 'ѕароль содержит недопустимо простую комбинацию символов, набранную повторно.';
   PASS_CONTAINS_KEYBOARD_SEQ constant varchar2(100) := '¬ пароле есть символы, набранные с клавиатуры подр€д кол-вом больше %1 раз.';
   PASSWORD_IS_BATTLEPASS constant varchar2(100) := 'ѕароль, совпадающий с инициализационным, запрещен.';
--
   procedure Check_BattlePass is
     type t_ref is ref cursor;
     v_ref t_ref;
     v_str varchar2(2000);
   begin
     begin
       open v_ref for
         'SELECT VALUE FROM AUD.SETTINGS WHERE NAME=:B1' using 'BATTLE_PASS';
     exception when others then null;
     end;
     if not v_ref%isopen then
       begin
         open v_ref for
          'SELECT VALUE FROM AUD.AUDIT_SETTINGS WHERE NAME=:B1' using 'BATTLE_PASS';
       exception when others then null;
       end;
     end if;
     if v_ref%isopen then
       loop
         fetch v_ref into v_str;
         exit when v_ref%notfound;
         if nls_lower(password) = nls_lower(v_str) then
           close v_ref;
           raise_application_error(-20001, PASSWORD_IS_BATTLEPASS);
         end if;
       end loop;
       close v_ref;
     end if;
   end;
--
   function revers(str_in in varchar2) return varchar2 is
    result  varchar2(40);
   begin
     for ii in reverse 1.. length(str_in) loop
       result := result ||substr(str_in,ii,1);
     end loop;
     return (result);
   end;
--
BEGIN
    if Old_password is null then
      -- „тобы обойти bug администратора доступа, который при создании
      -- пользовател€ - тупо ставит пароль равный имени.
      -- Everything is fine; return TRUE ;
     RETURN(TRUE);
    end if;
    IF ltrim(password) is null THEN
       raise_application_error(-20004, PASSWORD_IS_EMPTY);
    END IF;
--
   digitarray:= '0123456789';
--   chararray:= 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZйцукенгшщзхъфывапролджэ€чсмитьбю…÷” ≈Ќ√Ўў«’Џ‘џ¬јѕ–ќЋƒ∆Ёя„—ћ»“№Ѕё';
-- ƒо введени€ требовани€ по знакам пунктуации
   chararray := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%*+-=?_абвгдеЄжзийклмнопрстуфхцчшщъыьэю€јЅ¬√ƒ≈®∆«»… ЋћЌќѕ–—“”‘’÷„ЎўЏџ№Ёёя';
   punctarray:= '!#$%*+-=?_';
   badsymbols:= ' (){}[].,;:<>/|\"`''';
   qwerty_arrayLo    := '`1234567890-= qwertyuiop[]\ asdfghjkl;''\ \zxcvbnm,./';
   qwerty_array1Lo   := 'Є1234567890-= йцукенгшщзхъ\ фывапролджэ\ \€чсмитьбю.';
--
   -- Check if the password is same as the username
   IF nls_lower(password) = nls_lower(username) THEN
      raise_application_error(-20001, PASSWORD_IS_NAME);
   END IF;
--
   -- Check if the password is same as the battle password for user's creating accounts
   Check_BattlePass;
--
   -- Check for the minimum length of the password
   IF length(password) < 8 THEN
      raise_application_error(-20002, PASSWORD_IS_SHORT);
   END IF;
--
   -- Check if the password is too simple. A dictionary of words may be
   -- maintained and a check may be made so as not to allow the words
   -- that are too simple for the password.
   IF NLS_LOWER(password) IN ('welcome', 'database', 'account',  'password', 'oracle', 'computer','ibs','tst','test','ibso') THEN
      raise_application_error(-20002, PASSWORD_IS_SIMPLE);
   END IF;
--
   IF translate(password,badsymbols,lpad('?',length(badsymbols),'?'))=password THEN null; else
      raise_application_error(-20003, PASS_CONTAINS_BAD_CHARS);
   END IF;
--
   -- Check if the password contains at least one letter, one digit and one
   -- punctuation mark.
   -- 1. Check for the digit
   IF translate(password,digitarray,lpad(' ',length(digitarray)))=password THEN
      raise_application_error(-20003, PASS_MUST_CONTAIN_DIGITS);
   END IF;
   -- 2. Check for the character
   IF translate(password,chararray,lpad(' ',length(chararray)))=password THEN
      raise_application_error(-20003, PASS_MUST_CONTAIN_LETTERS);
   END IF;
   -- 3. Check for the punctuation
-- ƒо введени€ требовани€ по знакам пунктуации
   --IF translate(password,punctarray,lpad(' ',length(punctarray)))=password THEN
   --   raise_application_error(-20003, PASS_MUST_CONTAIN_DELIMETERS);
   --END IF;
--
   -- Check if the password differs from the previous password by at least
   -- 3 letters
   differ := abs(length(old_password) - length(password));
--
   IF differ < 3 THEN
      m := least(length(password),length(old_password));
      FOR i IN 1..m LOOP
          IF lower(substr(password,i,1)) != lower(substr(old_password,i,1)) THEN
             differ := differ + 1;
          END IF;
      END LOOP;
      IF differ < 3 THEN
          raise_application_error(-20004,
            replace(PASSES_MUST_DIFFER_IN_N_CHARS, '%1', 3));
      END IF;
   END IF;
--
   /* проверка на наличие повтор€ющихс€ символов кол-вом больше 2 */
   m := length(password);
   for i in 1..m-2 loop
     cur_sym := lpad(substr(password,i,1),3,substr(password,i,1));
     if instr(substr(password,i),cur_sym)>0 then
         raise_application_error(-20004, replace(PASS_CONTAINS_N_REPEATED_CHARS, '%1', 3));
     end if;
   end loop;
--
   /* проверка на наличие повтор€ющейс€ последовательности из 2-х символов кол-вом больше 2 */
   m := length(password);
   for i in 1..m-2 loop
     if instr(password,substr(password,i,2),i+2)>0 then
       raise_application_error(-20004, PASS_CONTAINS_SIMP_COMBINATION);
     end if;
   end loop;
--
   /* проверка на наличие символов идущих по пор€дку как и на клавиатуре кол-вом больше или = cnt_sym */
   cnt_sym := 4;
   m := length(password)-cnt_sym +1;
   isdigit := false;
   for i in 1..m loop
     cur_sym := Lower(substr(password,i,cnt_sym));
     cur_sym1:= translate(cur_sym,'~!@#$%^&*()_+{}|:"<>?','`1234567890-=[]\;'',./');
     cur_sym2:= translate(cur_sym,'!"є;%:?*()_+/|,','1234567890-=\\.');
     cur_sym_revers := revers(cur_sym);
     cur_sym_revers1:= revers(cur_sym1);
     cur_sym_revers2:= revers(cur_sym2);
   /* слева направо */
     if Instr(qwerty_arrayLo,cur_sym1) > 0 then isDigit := true;
     elsif Instr(qwerty_array1Lo,cur_sym2) > 0 then isDigit := true;
     elsif Instr(chararray,cur_sym) > 0 then isDigit := true;
   /* справа налево */
     elsif Instr(qwerty_arrayLo, cur_sym_revers1) > 0 then isDigit := true;
     elsif Instr(qwerty_array1Lo,cur_sym_revers2)> 0 then isDigit := true;
     elsif Instr(chararray,cur_sym_revers) > 0 then isDigit := true; end if;
     if isDigit then
       raise_application_error(-20004, replace(PASS_CONTAINS_KEYBOARD_SEQ, '%1', cnt_sym-1));
     end if;
   end loop;
--
   -- Everything is fine; return TRUE ;
   RETURN (TRUE);
--
END;
/
sho err

