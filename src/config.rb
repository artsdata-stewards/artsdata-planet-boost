module Config

  GENERAL_CONFIG = {
    user_agent: 'artsdata-crawler/3.3',
    do_not_load_websites: [
      "https://www.ville.lamalbaie.qc.ca",
      "https://www.sfo.org.uk/",
      "https://www.bushtheatre.co.uk/",
      "http://www.fretwork.co.uk/",
      "https://bonbonvodou.fr/",
      "https://www.thetallisscholars.co.uk/",
      "https://www.cie-koubi.fr/",
      "https://www.ballet.org.uk/"
    ]
  }.freeze
end
