#!/bin/bash
# Author: Bryant Treacle
# Date: 6/14/2018
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Purpose:  This script will allow you to build elastalert rules.
# The rule must be placed in the /etc/elastalert/rules directory.

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "This script must be run as root."
    exit
fi

print_welcome_message()
{
cat << EOF

This script will help automate the creation of Elastalert Rules. 
Please choose the rule you want to create.

For Cardinality rules: Press 1
For Blacklist rules: Press 2
Exit: Press 9

EOF 

}
# Function to exit loop
exit_prog()
{
    exit
}
# Declaring Cardinality welcome
print_cardinality_welcome()
{
cat << EOF

The Cardinality rule matches when the total number of unique values for a certain
field , within a given timeframe is higher or lower than a threshold.

Please complete the following options:

EOF
}

print_blacklist_welcome()
{ 
cat << EOF

The blacklist rule will check a field against a predefined list and match if the 
feild contains a value in the list.

Please complete the following options:

EOF
}
###############################################
# Functions to print universal rule prompts   #
###############################################
# Rule Name/File Name prompt
print_name_prompt()
{

cat << EOF
The rule name will appear in the subject of the alerts and be the name of the yaml rule file.

What do you want to name the rule?

EOF
}

# Elasticsearch index select
print_index_prompt()
{
cat << EOF

What elasticsearch index do you want to use?
Below are the default Index Patterns used in Security Onion:

*:logstash-*
*:logstash-beats-*
*:elastalert_status*

EOF
}

#  Alert options function
print_alertoptions()
{
cat << EOF

By default, all matches will be written back to the elastalert index.  If you would like to add an additional alert method please 
choose from the below options.

   - For Email: Press 1
   - For Slack: Press 2
   - For the default debug: Press 3

EOF

read alertoption

    if [ $alertoption = "1" ] ; then
        echo "Please enter the email address you want to send the alerts to.  Note: Ensure the Master Server is configured for SMTP."
	    read emailaddress
    elif [ $alertoption = "2" ] ; then
        echo "The webhook URL that includes your auth data and the ID of the channel (room) you want to post to."
	echo "Go to the Incoming Webhooks section in your Slack account https://XXXXX.slack.com/services/new/incoming-webhook ,"
	echo "choose the channel, click ‘Add Incoming Webhooks Integration’ and copy the resulting URL. You can use a list of URLs to send to multiple channels."
	echo ""
	echo "Please enter the webhook URL below:"
	    read webhookurl
    else
	echo "Using default alert type of debug.  Alerts will only be written to the *:elastalert_status* index."
        alertoption="debug"
    fi
}
# Filter options function
print_filteroptions()
{
cat << EOF

By default this script will use a wildcard seach that will include all logs for the index choosen above.
Would you like to use a specific filter? (Y/N)

EOF
    read filteroption
    if [ ${filteroption,,} = "y" ] ; then
        echo "This script will allow you to generate basic filters.  For complex filters visit https://elastalert.readthedocs.io/en/latest/recipes/writing_filters.html"
        echo ""
        echo "Term: Allows you to match a value in a field.  For example you can select the field source_ip and the value 192.168.1.1"
        echo "or choose a specific logtype you want the rule to apply to ie. field_type: event_type and the field_value bro_http"
        echo ""
        echo "Wildcard: Allows you to use the wildcard * in the field_value.  For example field_type: useragent and field_value: *Mozilla* "
        echo ""
        echo "Please choose from the following filter types."
        echo ""
        echo "term or wildcard"
            read filtertype
            if [ ${filtertype,,} = "term" ] ; then
                echo "What field do you want to use?"
                    read fieldtype
                echo "What is the value for the field."
                    read fieldvalue
            elif [ ${filtertype,,} = "wildcard" ] ; then
                echo "What field do you want to use?"
                    read fieldtype
                echo "What is the value for the field."
                    read fieldvalue
            fi
    else
        filtertype="wildcard"
        fieldtype="event_type"
        fieldvalue="*"
    fi
}

###################################
# Functions for Cardinality Rules #
###################################
cardinality_options()
{
    echo "The Cardinality Field will be  Count the number of unique values for this field."
    echo "What field do you want to be the Cardinality Field?"
    echo ""
        read cardinalityfield
    echo ""
    echo "To alert on values less than X unique values in the cardinality field: Press 1"
    echo ""
    echo "To alert on values greater than X unique values in the cardinality field: Press 2"
    echo ""
	read cardinality_max_min
    if [ $cardinality_max_min = "1" ] ; then
	echo "The Minimum Cardinality value will alert you when there is less than X unique values in that field."
    	echo "What is the minimum Cardinality value?"
    	echo ""
            read mincardinality
    elif [ $cardinality_max_min = "2" ] ; then
	echo "The Manimum Cardinality value will alert you when there is more than X unique values."
        echo "What is the maximum Cardinality value?"
        echo ""
            read maxcardinality
    fi
    echo ""
    echo "The Cardinality Timeframe is defined as the number of unique values in the most recent X hours."
    echo "What is the timeframe?"
    echo ""
       read timeframe
}

#########################################################################################


read userselect

if [ $userselect = "1" ] ; then
    echo "The Cardinality rule rule matches when a the total number of unique values for a certain field within a time frame is higher or lower than a threshold."
    echo "Please complete options"
    echo ""
    echo "What do you want to name the rule?"
    echo ""
        read rulename
    echo ""
    echo "What elasticsearch index do you want to search?"
    echo "Below are the default Index Patterns for Security Onion"
    echo ""
    echo "*:logstash-bro*"
    echo "*:logstash-beats*"
    echo "*:elastalert_status*"
    echo ""
        read indexname
    echo "The Cardinality Field will be  Count the number of unique values for this field."
    echo "What field do you want to be the Cardinality Field?"
    echo ""
        read cardinalityfield
    echo ""
    echo "The Minimum Cardinality value will alert you when there is less than X unique values in that field."
    echo "What is the minimum Cardinality value?"
    echo ""
        read mincardinality
    echo ""
    echo "The Manimum Cardinality value will alert you when there is more than X unique values."
    echo "What is the maximum Cardinality value?"
    echo ""
        read maxcardinality
    echo ""
    echo "The Cardinality Timeframe is defined as the number of unique values in the most recent X hours."
    echo "What is the timeframe?"
    echo ""
       read timeframe
    echo ""
    echo "By default, all matches will be written back to the elastalert index.  If you would like to add an additional alert method please"
    echo "choose from the below options. To use the default type debug."
    echo ""
	read alertoption
  	
	if [ ${alertoption,,} = "debug" ] ; then
	    echo "Using default alert type of debug.  Alerts will only be written to the *:elastalert_status* index"
	fi
    echo ""
    echo "By default this script will use a wildcard seach that will include all logs for the index choosen above."
    echo "Would you like to use a specific filter? (Y/N)"
	read filteroption

	if [ ${filteroption,,} = "y" ] ; then
	    echo "This script will allow you to generate basic filters.  For complex filters visit https://elastalert.readthedocs.io/en/latest/recipes/writing_filters.html"
	    echo ""
	    echo "Term: Allows you to match a value in a field.  For example you can select the field source_ip and the value 192.168.1.1"
	    echo "or choose a specific logtype you want the rule to apply to ie. field_type: event_type and the field_value bro_http"
	    echo ""
	    echo "Wildcard: Allows you to use the wildcard * in the field_value.  For example field_type: useragent and field_value: *Mozilla* "
	    echo ""
            echo "Please choose from the following filter types."
	    echo ""
	    echo "term or wildcard"
		read filtertype

		if [ ${filtertype,,} = "term" ] ; then
		    echo "What field do you want to use?"
			read fieldtype
		    echo "What is the value for the field."
			read fieldvalue
		elif [ ${filtertype,,} = "wildcard" ] ; then
		    echo "What field do you want to use?"
                        read fieldtype
                    echo "What is the value for the field."
                        read fieldvalue
		fi
	else
	filtertype="wildcard"
	fieldtype="event_type"
	fieldvalue="*"
	fi
    echo ""
    echo "below are the following options that will be configured:"
    echo "    Rule Name: $rulename"
    echo "    Index: $indexname"
    echo "    Cardinality Field: $cardinalityfield"
    echo "    Min Cardinality: $mincardinality"
    echo "    Max Cardinality: $maxcardinality"
    echo "    Timeframe: $timeframe"
    echo "    Alert option: $alertoption"
#    echo "    Email Address: $emailaddress"
    echo "    Filter Type: $filtertype"
    echo "    Field Type: $fieldtype"
    echo "    Field Value: $fieldvalue"
    echo ""
    echo "Would you like to proceed? (Y/N)"
	read buildrule
	
	if [ ${buildrule,,} = "n" ] ; then
	    echo "The Cardinality rule rule matches when a the total number of unique values for a certain field within a time frame is higher or lower than a threshold."
    	    echo "Please complete options"
    	    echo ""
    	    echo "What do you want to name the rule?"
            echo ""
        	read rulename
    	    echo ""
    	    echo "What elasticsearch index do you want to search?"
    	    echo "Below are the default Index Patterns for Security Onion"
    	    echo ""
    	    echo "*:logstash-bro*"
    	    echo "*:logstash-beats*"
    	    echo "*:elastalert_status*"
     	    echo ""
        	read indexname
    	    echo "The Cardinality Field will be  Count the number of unique values for this field."
    	    echo "What field do you want to be the Cardinality Field?"
    	    echo ""
        	read cardinalityfield
    	    echo ""
    	    echo "The Minimum Cardinality value will alert you when there is less than X unique values"
    	    echo "What is the minimum Cardinality value?"
    	    echo ""
        	read mincardinality
	    echo ""
    	    echo "The Manimum Cardinality value will alert you when there is more than X unique values."
    	    echo "What is the maximum Cardinality value?"
    	    echo ""
        	read maxcardinality
    	    echo ""
    	    echo "The Cardinality Timeframe is defined as the number of unique values in the most recent X hours."
   	    echo "What is the timeframe?"
    	    echo ""
       		read timeframe
	    echo ""
    	    echo "By default, all matches will be written back to the elastalert index.  If you would like to add an additional alert method please"
   	    echo "choose from the below options. To use the default Email type email."
    	    echo ""
    	    echo "By default, all matches will be written back to the elastalert index.  If you would like to add an additional alert method please"
    	    echo "choose from the below options. To use the default type debug."
    	    echo ""
       		 read alertoption

        	if [ ${alertoption,,} = "debug" ] ; then
           	    echo "Using default alert type of debug.  Alerts will only be written to the *:elastalert_status* index"
        	fi

	    echo ""
    	    echo "By default this script will use a wildcard seach that will include all logs for the index choosen above."
    	    echo "Would you like to use a specific filter? (Y/N)"
        	read filteroption

        	if [ ${filteroption,,} = "y" ] ; then
            	    echo "This script will allow you to generate basic filters.  For complex filters visit https://elastalert.readthedocs.io/en/latest/recipes/writing_filters.html"
            	    echo ""
            	    echo "Term: Allows you to match a value in a field.  For example you can select the field source_ip and the value 192.168.1.1"
            	    echo "or choose a specific logtype you want the rule to apply to ie. field_type: event_type and the field_value bro_http"
            	    echo ""
            	    echo "Wildcard: Allows you to use the wildcard * in the field_value.  For example field_type: useragent and field_value: *Mozilla* "
            	    echo ""
            	    echo "Please choose from the following filter types."
            	    echo ""
            	    echo "term or wildcard"
                	read filtertype

	                if [ ${filtertype,,} = "term" ] ; then
	                    echo "What field do you want to use?"
                            read fieldtype
                            echo "What is the value for the field."
                            read fieldvalue
                	elif [ ${filtertype,,} = "wildcard" ] ; then
                    	    echo "What field do you want to use?"
                            read fieldtype
                            echo "What is the value for the field."
                            read fieldvalue
                	fi
        	else
        	    filtertype="wildcard"
        	    fieldtype="event_type"
        	    fieldvalue="*"
        	fi
            echo ""
	    echo "below are the following options that will be configured:"
            echo "    Rule Name: $rulename"
    	    echo "    Index: $indexname"
    	    echo "    Cardinality Field: $cardinalityfield"
    	    echo "    Min Cardinality: $mincardinality"
    	    echo "    Max Cardinality: $maxcardinality"
    	    echo "    Timeframe: $timeframe"
    	    echo "    Alert option: $alertoption"
    	   # echo "    Email Address: $emailaddress"
    	    echo "    Filter Type: $filtertype"
    	    echo "    Field Type: $fieldtype"
    	    echo "    Field Value: $fieldvalue"
    	    echo ""
	    echo "Would you like to proceed? (Y/N)"
	       read buildrule
		if [ ${buildrule,,} = "n" ] ;then
	        exit
	        fi
	fi
	    currentdirectory=$(pwd)
	    echo "building rule and placing it in the following directory: $currentdirectory "
	    echo ""
	    echo "I recommend you test the rule by using the so-elastalert-test-rule script"
	    echo ""
	    echo "After you test the script, move it to the /etc/elastalert/rules on the Master Node."
	        cp cardinality_rule_template.yaml $rulename.yaml
	        sed -i 's|name-placeholder|'"$rulename"'|g' $rulename.yaml 
		sed -i 's|index-placeholder|'"$indexname"'|g' $rulename.yaml
		sed -i 's|cardinality-field-placeholder|'"$cardinalityfield"'|g' $rulename.yaml
		sed -i 's|min_cardinality-placeholder|'"$mincardinality"'|g' $rulename.yaml
                sed -i 's|max_cardinality-placeholder|'"$maxcardinality"'|g' $rulename.yaml
		sed -i 's|timeframe-placeholder|'"$timeframe"'|g' $rulename.yaml
		sed -i 's|alert-placeholder|'"$alertoption"'|g' $rulename.yaml
	#	sed -i 's|alert-option-placeholder|'"$alertoption"'|g' $rulename.yaml
	#	sed -i 's|alert-option-value-placeholder|'"$emailaddress"'|g' $rulename.yaml
		sed -i 's|filter-type-placeholder|'"$filtertype"'|g' $rulename.yaml
		sed -i 's|field-type-placeholder|'"$fieldtype"'|g' $rulename.yaml
		sed -i 's|field-value-placeholder|'"$fieldvalue"'|g' $rulename.yaml
elif [ $userselect = "2" ] ; then
    echo "The CardinaliThe blacklist rule will check a certain field against a blacklist, and match if it is in the blacklist."
    echo "Please complete options"
    echo ""
    echo "What do you want to name the rule?"
    echo ""
        read rulename
    echo ""
    echo "What elasticsearch index do you want to search?"
    echo "Below are the default Index Patterns for Security Onion"
    echo ""
    echo "*:logstash-bro*"
    echo "*:logstash-beats*"
    echo "*:elastalert_status*"
    echo ""
        read indexname
    echo "The blacklist rule will check a certain field against a blacklist, and match if it is in the blacklist."
    echo "What field do you want to compare to the blacklist?"
    echo ""
        read comparekey
    echo ""
    echo "The blacklist file should be a text file with a single value per line."
    echo ""
    echo "The file needs to be accesable by the so-logstash container. I recomend placing it in the /etc/elastaler/rules directory."
    echo "Where is the location of the blacklist file?"
    echo ""
        read blacklistfile
    echo ""
    echo "By default, all matches will be written back to the elastalert index.  If you would like to add an additional alert method please"
    echo "choose from the below options. To use the default Email type email."
    echo ""
    echo "By default, all matches will be written back to the elastalert index.  If you would like to add an additional alert method please"
    echo "choose from the below options. To use the default type debug."
    echo ""
        read alertoption

        if [ ${alertoption,,} = "debug" ] ; then
            echo "Using default alert type of debug.  Alerts will only be written to the *:elastalert_status* index"
        fi
    echo ""
    echo "By default this script will use a wildcard seach that will include all logs for the index choosen above."
    echo "Would you like to use a specific filter? (Y/N)"
        read filteroption

           if [ ${filteroption,,} = "y" ] ; then
                echo "This script will allow you to generate basic filters.  For complex filters visit https://elastalert.readthedocs.io/en/latest/recipes/writing_filters.html"
                echo ""
                echo "Term: Allows you to match a value in a field.  For example you can select the field source_ip and the value 192.168.1.1"
                echo "or choose a specific logtype you want the rule to apply to ie. field_type: event_type and the field_value bro_http"
                echo ""
                echo "Wildcard: Allows you to use the wildcard * in the field_value.  For example field_type: useragent and field_value: *Mozilla* "
                echo ""
                echo "Please choose from the following filter types: term or wildcard "
                echo ""
                    read filtertype

                    if [ ${filtertype,,} = "term" ] ; then
                        echo "What field do you want to use?"
                        read fieldtype
                        echo "What is the value for the field."
                        read fieldvalue
                    elif [ ${filtertype,,} = "wildcard" ] ; then
                        echo "What field do you want to use?"
                        read fieldtype
                        echo "What is the value for the field."
                        read fieldvalue
                    fi
            else
                filtertype="wildcard"
                fieldtype="event_type"
                fieldvalue="*"
            fi
    echo ""
    echo "below are the following options that will be configured:"
    echo "    Rule Name: $rulename"
    echo "    Index: $indexname"
    echo "    Compare Key: $comparekey"
    echo "    Blacklist file location: $blacklistfile/$rulename.yaml"
    echo "    Alert option: $alertoption"
#    echo "    Email Address: $emailaddress"
    echo "    Filter Type: $filtertype"
    echo "    Field Type: $fieldtype"
    echo "    Field Value: $fieldvalue"
    echo ""
    echo "Would you like to proceed? (Y/N)"
        read buildrule
        
        if [ ${buildrule,,} = "n" ] ;then
            exit
        fi
    currentdirectory=$(pwd)
    echo "building rule and placing it in the following directory: $currentdirectory "
    echo ""
    echo "I recommend you test the rule by using the so-elastalert-test-rule script"
    echo ""
    echo "After you test the script, move it to the /etc/elastalert/rules on the Master Node."
        cp blacklist_rule_template.yaml $rulename.yaml
        sed -i 's|name-placeholder|'"$rulename"'|g' $rulename.yaml
        sed -i 's|index-placeholder|'"$indexname"'|g' $rulename.yaml
        sed -i 's|compare-key-placeholder|'"$comparekey"'|g' $rulename.yaml
        sed -i 's|blacklist-file-placeholder|'"$blacklistfile/$rulename.yaml"'|g' $rulename.yaml
        sed -i 's|alert-placeholder|'"$alertoption"'|g' $rulename.yaml
       # sed -i 's|alert-option-placeholder|'"$alertoption"'|g' $rulename.yaml
       # sed -i 's|alert-option-value-placeholder|'"$emailaddress"'|g' $rulename.yaml
        sed -i 's|filter-type-placeholder|'"$filtertype"'|g' $rulename.yaml
        sed -i 's|field-type-placeholder|'"$fieldtype"'|g' $rulename.yaml
        sed -i 's|field-value-placeholder|'"$fieldvalue"'|g' $rulename.yaml

fi




