metadata :name        => "Chef Agent",
         :description => "",
         :author      => "Jordan Curzon",
         :license     => "",
         :version     => "1.0",
         :url         => "",
         :timeout     => 180

action "node_json", :description => "" do
  display :always  # supported in 0.4.7 and newer only

  output :data,
    :description => "Raw JSON from the last chef run",
    :display_as  => "JSON"
end

action "deploy", :description => "" do
  display :always  # supported in 0.4.7 and newer only
end

