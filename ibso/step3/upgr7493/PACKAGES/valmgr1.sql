prompt valmgr
create or replace package valmgr as
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/IBS/valmgr1.sql $
 *  $Author: vzhukov $
 *  $Revision: 125683 $
 *  $Date:: 2016-10-26 08:29:19 #$
 */
-- for ref
    type referencing_info is record(
        class_id   varchar2(16),
        class_name varchar2(128),
        qual varchar2(700),
        qual_name varchar2(8000),
        in_collection varchar2(10)
    );
    type referencing_info_table is table of referencing_info index by binary_integer;
-- for triggers
    type qual_info is record(
        qual varchar2(700),
        base varchar2(16),
        class varchar2(16),
        refclass varchar2(16),
        oldv varchar2(4000),
        newv varchar2(4000)
    );
    type qual_table is table of qual_info index by binary_integer;
    trigger_flag  boolean := true;
--
function parent_qualifier(q varchar2) return varchar2;
function get_def_qual(p_class_id varchar2) return varchar2;
function get_obj_name(p_obj_id varchar2, p_class_id varchar2 default null) return varchar2;

function is_parent ( p_parent_class IN varchar2,
                     p_child_class  IN varchar2
                   ) return varchar2 deterministic;
pragma restrict_references(is_parent, WNDS, WNPS, TRUST);

procedure check_delete(p_class varchar2);
procedure check_update(p_class varchar2);
procedure check_insert(p_class varchar2);
procedure check_cached(p_list varchar2,p_obj varchar2 default null);
function  coll_log(p_class varchar2) return boolean;
function  rowcount return number;
pragma restrict_references(rowcount, WNDS, WNPS, TRUST);

procedure clear_hard_colls(p_obj_id varchar2);
procedure add_hard_coll(p_coll_id number,p_qual varchar2,p_obj_id varchar2);
function  get_hard_coll(p_coll_id out nocopy number, p_qual out nocopy varchar2) return boolean;

procedure check_refs(obj_id_ number, qual_ varchar2, val_ number, old_ number, class_id_ varchar2 default null);
procedure refs_check(obj_id_ number, qual_ varchar2, val_ number, old_ number, class_id_ varchar2 default null);
procedure coll_check(obj_id_ number, qual_ varchar2, val_ number, old_ number, class_id_ varchar2 default null);

function char2bool(char_ varchar2) return boolean  deterministic;
function bool2char(bool_ boolean)  return varchar2 deterministic;
pragma restrict_references(char2bool, WNDS, WNPS);
pragma restrict_references(bool2char, WNDS, WNPS);


function any2char(any_ varchar2) return varchar2 deterministic;
pragma restrict_references(any2char, WNDS, WNPS);
function any2char(any_ number) return varchar2 deterministic;
pragma restrict_references(any2char, WNDS, WNPS);
function any2char(any_ date) return varchar2 deterministic;
pragma restrict_references(any2char, WNDS, WNPS);
function any2char(any_ boolean) return varchar2 deterministic;
pragma restrict_references(any2char, WNDS, WNPS);

procedure check_qual(qual_ in out nocopy varchar2, class_ in out nocopy varchar2);
procedure split_class(class_list_ in out nocopy varchar2,
                      class_  in out nocopy varchar2,
                      parent_ varchar2);

procedure new_object(class_id_ in varchar2, collection_id_ in number, obj_id_ out nocopy varchar2);
function  new_object(class_id_ in varchar2, collection_id_ in number default null) return varchar2;

function  editable_column(class_id_ varchar2, qual_ varchar2) return boolean;
procedure set_value(obj_id_ in varchar2,qual_ in varchar2, value_ in varchar2, class_ varchar2 default null);
function  get_value(obj_id_ in varchar2,qual_ in varchar2, class_  in varchar2 default null ) return varchar2;

--
function first_referencing_on(p_object_id varchar2, p_class_id varchar2,
                              p_chk pls_integer default null, p_refcing varchar2 default null) return varchar2;
function next_referencing(p_class_id out nocopy varchar2, p_class_name out nocopy varchar2,
                          p_qual out nocopy varchar2, p_qual_name out nocopy varchar2, p_in_coll out nocopy varchar2) return varchar2;
function get_refs_list return varchar2;
--
function hash_idx(p_str varchar2) return pls_integer deterministic;
pragma restrict_references(hash_idx, WNDS, WNPS);
function add_qual(p_qual varchar2, p_base varchar2, p_class varchar2, p_refclass varchar2,
                  p_old  varchar2, p_new  varchar2,
                  p_clear boolean  default false,
                  p_event varchar2 default null) return boolean;
function get_qual(p_value out nocopy varchar2, p_qual varchar2,
                  p_clear boolean default false) return boolean;
function  chk_quals(p_quals in out nocopy qual_table, p_event varchar2 default null) return boolean;
procedure get_quals(p_quals in out nocopy qual_table);
procedure set_quals(p_quals in out nocopy qual_table);
--
function static(p_class varchar2,p_err boolean default false) return varchar2 deterministic;
pragma restrict_references(static, TRUST, WNDS, WNPS);
procedure put_static(p_class varchar2,p_id varchar2);
procedure del_static(p_class varchar2);
procedure init_stat(p_class varchar2 default null);
pragma restrict_references(init_stat, WNDS);
--
function  get_key ( p_class  varchar2 ) return number deterministic;
pragma restrict_references(get_key, TRUST, WNDS, WNPS);
procedure set_key ( p_class varchar2, p_key number, p_update boolean default true );
procedure init_keys(p_class varchar2 default null, p_reset boolean default true);
pragma restrict_references(init_keys, TRUST, WNDS);
function  init_key( p_flag  pls_integer ) return number deterministic;
pragma restrict_references(init_key, TRUST, WNDS, WNPS);
procedure switch_archiving( p_actual boolean default true );
--
procedure init_packs(p_class varchar2, p_self boolean default false);
procedure reset_class (p_class varchar2 default null);
pragma restrict_references(reset_class, WNDS);
function  class_inited(p_class varchar2) return varchar2 deterministic;
pragma restrict_references(class_inited,WNDS, WNPS);
function  init_class(p_class varchar2) return varchar2;
function  class_inited_last return varchar2;
pragma restrict_references(class_inited,WNDS, WNPS);
--
procedure init_settings;
pragma restrict_references(init_settings, WNDS);
procedure check_priority(p_level pls_integer);
procedure check_readonly;
function  set_readonly(p_readonly boolean) return varchar2;
function  is_readonly return boolean;
--
function class_state(p_class varchar2) return varchar2 deterministic;
pragma restrict_references(class_state, TRUST, WNDS, WNPS);
--
procedure set_context( p_name varchar2, p_value varchar2,
                       p_username  varchar2 default null,
                       p_client_id varchar2 default null);
procedure clear_context(p_client_id varchar2 default null,
                        p_name      varchar2 default null);
--
end valmgr;
/
show err

