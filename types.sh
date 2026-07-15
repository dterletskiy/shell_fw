[ -n "${__SFW_TYPES_SH__}" ] && return 0 || readonly __SFW_TYPES_SH__=1

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/log.sh"



#
# Get the attributes of a Bash variable.
#
# Determines the attributes of a variable and returns them as an
# indexed array.
#
# Arguments:
#   $1 - variable name
#   $2 - output array name (nameref)
#
# Return codes:
#   0 - success
#   1 - variable does not exist
#
# Returned attributes:
#   scalar              - regular variable
#   array               - indexed array (declare -a)
#   map                 - associative array (declare -A)
#   integer             - integer variable (declare -i)
#   readonly            - read-only variable (declare -r)
#   exported            - exported variable (declare -x)
#   lowercase           - convert assigned values to lowercase (declare -l)
#   uppercase           - convert assigned values to uppercase (declare -u)
#   nameref             - name reference (declare -n)
#   trace               - trace attribute (declare -t)
#
# Example:
#   declare -ir counter=10
#
#   declare -a attributes
#
#   get_variable_attributes counter attributes
#
#   printf '%s\n' "${attributes[@]}"
#
function get_variable_attributes( )
{
   local var_name="$1"
   local -n out_ref_gva=$2

   out_ref_gva=()

   local decl
   decl=$( declare -p "$var_name" 2> /dev/null ) || return 1

   local flags

   if [[ "$decl" =~ ^declare[[:space:]]-([A-Za-z]+)[[:space:]] ]]; then
      flags="${BASH_REMATCH[1]}"
   else
      out_ref_gva+=( "scalar" )
      return 0
   fi

   [[ "$flags" == *a* ]] && out_ref_gva+=( "array" )
   [[ "$flags" == *A* ]] && out_ref_gva+=( "map" )
   [[ "$flags" == *i* ]] && out_ref_gva+=( "integer" )
   [[ "$flags" == *r* ]] && out_ref_gva+=( "readonly" )
   [[ "$flags" == *x* ]] && out_ref_gva+=( "exported" )
   [[ "$flags" == *l* ]] && out_ref_gva+=( "lowercase" )
   [[ "$flags" == *u* ]] && out_ref_gva+=( "uppercase" )
   [[ "$flags" == *n* ]] && out_ref_gva+=( "nameref" )
   [[ "$flags" == *t* ]] && out_ref_gva+=( "trace" )

   if [[ ${#out_ref_gva[@]} -eq 0 ]]; then
      out_ref_gva+=( "scalar" )
   fi

   return 0
}



#
# Get the type of a Bash variable.
#
# Determines the primary type of a variable.
#
# Arguments:
#   $1 - variable name
#   $2 - output variable name (nameref)
#
# Return codes:
#   0 - success
#   1 - variable does not exist
#
# Returned types:
#   scalar
#   array
#   map
#   integer
#   nameref
#
# Example:
#   declare value
#   declare -a array
#
#   declare type
#
#   get_variable_type value type
#   echo "$type"
#   # scalar
#
#   get_variable_type array type
#   echo "$type"
#   # array
#
function get_variable_type( )
{
   local var_name="$1"
   local -n out_ref_gvt=$2

   out_ref_gvt=""

   declare -a attributes
   get_variable_attributes "$var_name" attributes || return 1
   # log_info "attributes: ${attributes[@]}"

   local attribute
   for attribute in "${attributes[@]}"; do
      case "$attribute" in
         array|map|nameref|integer)
            out_ref_gvt="$attribute"
            return 0
         ;;
      esac
   done

   out_ref_gvt="scalar"
   return 0
}



function test_get_variable_attributes( )
{
   declare value="abc"
   declare variable
   declare -a array
   declare -A map
   declare -ir count=10
   declare -nx ref=value

   declare -a attrs
   declare type

   log_info "value=${value}"
   get_variable_attributes value attrs
   log_debug "   $?: ${attrs[@]}"
   get_variable_type value type
   log_debug "   $?: ${type}"
   # scalar

   log_info "variable=${variable}"
   get_variable_attributes variable attrs
   log_debug "   $?: ${attrs[@]}"
   get_variable_type variable type
   log_debug "   $?: ${type}"
   # scalar

   log_info "array=${array}"
   get_variable_attributes array attrs
   log_debug "   $?: ${attrs[@]}"
   get_variable_type array type
   log_debug "   $?: ${type}"
   # array

   log_info "map=${map}"
   get_variable_attributes map attrs
   log_debug "   $?: ${attrs[@]}"
   get_variable_type map type
   log_debug "   $?: ${type}"
   # map

   log_info "count=${count}"
   get_variable_attributes count attrs
   log_debug "   $?: ${attrs[@]}"
   get_variable_type count type
   log_debug "   $?: ${type}"
   # integer readonly

   log_info "ref=${ref}"
   get_variable_attributes ref attrs
   log_debug "   $?: ${attrs[@]}"
   get_variable_type ref type
   log_debug "   $?: ${type}"
   # nameref exported

   log_info "undefined=${undefined}"
   get_variable_attributes undefined attrs
   log_debug "   $?: ${attrs[@]}"
   get_variable_type undefined type
   log_debug "   $?: ${type}"
   # nameref exported
}
