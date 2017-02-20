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
  -- ���������
  --------------------------------------------------
  /**
  * ������� ���������� ���������������� �����
  * @param p_build
  * <ul>
  *   <li><code>true</code> ��������������� ����.
  *   <li><code>false</code> �� ��������������� ����.
  *   <li><code>null</code> ��������������� ����,
  *     �� �� ��������� ��������� ������. ����
  *     ����� ������������ ��� ����������� � ��������.
  * </ul>
  */
  PROCEDURE Grants(p_build boolean default TRUE);
  
  /**
  * ������� ���������� ���������������� ���� OWNER_APPSRV
  * @param p_build
  * <ul>
  *   <li><code>true</code> ��������������� ���� OWNER_APPSRV.
  *   <li><code>false</code> �� ��������������� ���� OWNER_APPSRV.
  *   <li><code>null</code> ��������������� ���� OWNER_APPSRV,
  *     �� �� ��������� �� �������������.
  * </ul>
  */
  PROCEDURE GrantsAppSrv(p_build boolean default TRUE);
  ---------------------------------------------------------------------
  -- ������� ����� � ����������� �� ������� �������������
  ---------------------------------------------------------------------
  PROCEDURE Grant_Roles(p_appsrv boolean);
  PROCEDURE Create_Contexts;
  --------------------------------------------------
  -- ������������ View ���������
  PROCEDURE ReCreate_Vw_Crit(OutPut IN VARCHAR2 Default NULL);
  --------------------------------------------------
  -- �������������� ���� �������� �� ������� Procedures
  PROCEDURE ReCompile_Proc;
  --------------------------------------------------
  -- �������� ���� ��������, ���� �� ���
  PROCEDURE Recreate_Indexes;
  --------------------------------------------------
  -- �������������� � ������������ ������������������
  PROCEDURE ReBuild;
  --------------------------------------------------
  PROCEDURE GrantProcedures(ProcName IN VARCHAR2 DEFAULT NULL);
  --------------------------------------------------
  -- ������������ views � triggers ��������������
  PROCEDURE Create_Diarys(OutPut IN VARCHAR2 Default NULL);
  --------------------------------------------------
  -- ������������ views, �����, ������������ ��� ������������.
  -- ������� ����������.
  PROCEDURE Create_Partitioning(p_build boolean default TRUE);
  --------------------------------------------------
END;
/
sho err
