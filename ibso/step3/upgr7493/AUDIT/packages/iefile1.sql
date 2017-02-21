prompt ie_file
create or replace package ie_file is
/*
 *  $HeadURL: http://hades.ftc.ru:7382/svn/pltm2/CorePkg/tags/7.4.9.3/AUD/iefile1.sql $
 *  $Author: Alexey $
 *  $Revision: 15071 $
 *  $Date:: 2012-03-06 13:38:04 #$
 */

type diary_rec_t is record (
  id number,
  time varchar2(30),
  owner varchar2 (30),
  user_id varchar2 (50),
  topic char (1),
  text varchar2 (2000)
);
type diary_param_rec_t is record (
  diary_id number,
  qual varchar2(700),
  text varchar2(2000)
);
type object_state_history_rec_t is record (
  id number,
  time varchar2(30),
  owner varchar2 (30),
  user_id varchar2(70),
  obj_id  varchar2(128),
  state_id varchar2(16)
);
type values_history_rec_t is record (
  id number,
  time varchar2(30),
  owner varchar2 (30),
  user_id varchar2 (70),
  obj_id varchar2 (128),
  qual varchar2 (700),
  base_id varchar2 (16),
  value varchar2 (2000)
);
type diary_n_rec_t is record (
  id number,
  time varchar2(30),
  audsid number,
  user_id varchar2 (70),
  topic char (1),
  code varchar2 (30),
  text varchar2 (4000)
);
type dp_rec_t is record (
  diary_id number,
  time varchar2(30),
  qual varchar2 (700),
  base_id varchar2 (16),
  text varchar2 (4000)
);
type och_rec_t is record (
  id number,
  time varchar2(30),
  obj_id   varchar2(128),
  class_id varchar2(16),
  collection_id number,
  obj_parent varchar2 (2000),
  audsid number,
  user_id varchar2 (70)
);
type osh_rec_t is record (
  id number,
  time varchar2(30),
  obj_id   varchar2(128),
  class_id varchar2(16),
  state_id varchar2 (16),
  audsid number,
  user_id varchar2 (70)
);
type valsh_rec_t is record (
  id number,
  time varchar2(30),
  obj_id   varchar2(128),
  class_id varchar2(16),
  audsid number,
  user_id varchar2 (70),
  qual varchar2 (700),
  base_id varchar2 (16),
  value varchar2 (4000)
);
type edh_rec_t is record (
  id number,
  time varchar2(30),
  obj_id   varchar2(128),
  class_id varchar2(16),
  audsid number,
  user_id varchar2 (70),
  type_id varchar2 (16),
  code varchar2 (70),
  text varchar2 (4000)
);

function quote_date(field varchar2) return varchar2;
function quote_timestamp(field varchar2) return varchar2;
function quote_text(field varchar2) return varchar2;

function dequote_date(place_holder varchar2) return varchar2;
function dequote_timestamp(place_holder varchar2) return varchar2;
function dequote_text(place_holder varchar2) return varchar2;
function convert_text(place_holder varchar2) return varchar2;

procedure start_exp(p_file_path varchar2, p_file_name varchar2, p_append boolean default false);
procedure start_table_exp(p_owner in varchar2, p_table_name in varchar2, p_date in date);

procedure put(diary_rec in out nocopy diary_rec_t);
procedure put(dp_rec in out nocopy diary_param_rec_t);
procedure put(osh_rec in out nocopy object_state_history_rec_t);
procedure put(valsh_rec in out nocopy values_history_rec_t);

procedure put(diary_n_rec in out nocopy diary_n_rec_t);
procedure put(dp_rec in out nocopy dp_rec_t);
procedure put(och_rec in out nocopy och_rec_t);
procedure put(osh_rec in out nocopy osh_rec_t);
procedure put(valsh_rec in out nocopy valsh_rec_t);
procedure put(edh_rec in out nocopy edh_rec_t);

procedure finish_table_exp;
procedure finish_exp;

procedure start_imp(p_file_path varchar2, p_file_name varchar2);
function get_next_table(p_code out pls_integer, p_owner out varchar2, p_date out date) return boolean;

function get(diary_rec in out nocopy diary_rec_t) return boolean;
function get(dp_rec in out nocopy diary_param_rec_t) return boolean;
function get(osh_rec in out nocopy object_state_history_rec_t) return boolean;
function get(valsh_rec in out nocopy values_history_rec_t) return boolean;

function get(diary_n_rec in out nocopy diary_n_rec_t) return boolean;
function get(dp_rec in out nocopy dp_rec_t) return boolean;
function get(och_rec in out nocopy och_rec_t) return boolean;
function get(osh_rec in out nocopy osh_rec_t) return boolean;
function get(valsh_rec in out nocopy valsh_rec_t) return boolean;
function get(edh_rec in out nocopy edh_rec_t) return boolean;

procedure finish_imp;

function get_table_name return varchar2;
function get_lines_count return pls_integer;
function get_total_lines_count return pls_integer;
function get_field_pos return pls_integer;
procedure cleanup_table_inf;

end;
/
show err

