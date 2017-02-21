prompt After_Install
CREATE OR REPLACE PACKAGE After_Install IS
  /*
  *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/ai1.sql $
  *  $Author: dashkevich $
  *  $Revision: 74514 $
  *  $Date:: 2015-06-18 12:01:17 #$
  */
  --------------------------------------------------
  verbose   boolean := false;
  pipe_name varchar2(30) := 'AFTER_INSTALL';
  --------------------------------------------------
  -- Процедуры
  --------------------------------------------------
  /**
  * Раздача привилегий пользовательским ролям
  * @param p_build
  * <ul>
  *   <li><code>true</code> Пересоздаватать роли.
  *   <li><code>false</code> НЕ пересоздаватать роли.
  *   <li><code>null</code> Пересоздаватать роли,
  *     но не раздавать некоторые гранты. Этот
  *     режим используется при инсталляции и апгрэйде.
  * </ul>
  */
  PROCEDURE Grants(p_build boolean default TRUE);
  
  /**
  * Раздача привилегий пользовательской роли OWNER_APPSRV
  * @param p_build
  * <ul>
  *   <li><code>true</code> Пересоздаватать роль OWNER_APPSRV.
  *   <li><code>false</code> НЕ пересоздаватать роль OWNER_APPSRV.
  *   <li><code>null</code> Пересоздаватать роль OWNER_APPSRV,
  *     но не раздавать ее пользователям.
  * </ul>
  */
  PROCEDURE GrantsAppSrv(p_build boolean default TRUE);
  ---------------------------------------------------------------------
  -- Раздача ролей в зависимости от свойств пользователей
  ---------------------------------------------------------------------
  PROCEDURE Grant_Roles(p_appsrv boolean);
  PROCEDURE Create_Contexts;
  --------------------------------------------------
  -- Пересоздание View критериев
  PROCEDURE ReCreate_Vw_Crit(OutPut IN VARCHAR2 Default NULL);
  --------------------------------------------------
  -- Перекомпиляция всех процедур из таблицы Procedures
  PROCEDURE ReCompile_Proc;
  --------------------------------------------------
  -- Создание всех индексов, если их нет
  PROCEDURE Recreate_Indexes;
  --------------------------------------------------
  -- Перекомпиляция и пересоздание вышеперечисленного
  PROCEDURE ReBuild;
  --------------------------------------------------
  PROCEDURE GrantProcedures(ProcName IN VARCHAR2 DEFAULT NULL);
  --------------------------------------------------
  -- Пересоздание views и triggers журналирования
  PROCEDURE Create_Diarys(OutPut IN VARCHAR2 Default NULL);
  --------------------------------------------------
  -- Пересоздание views, типов, используемых при партификации.
  -- Раздача привилегий.
  PROCEDURE Create_Partitioning(p_build boolean default TRUE);
  --------------------------------------------------
END;
/
sho err
