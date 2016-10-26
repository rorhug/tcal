class Testimonial
  LIST = [
    {
      enabled: :admin_only,
      name: "Owen Shepherd",
      course: "Computer Science, 2nd Year",
      message: %Q{
Tcal is the sexiest tool to replace TCD's pathetic attempt at getting a useful calendar, MyDay.

It's great that one CS student can write a better system, for free, than the one TCD undoubtedly paid far too much for.
      }
    },
    {
      enabled: true,
      name: "Sam Daly",
      course: "BESS, 2nd year",
      message: %Q{
It's beautiful
      }
    },
    {
      enabled: true,
      name: "Eoin McMahon",
      course: "Science, 3rd year",
      message: %Q{
It's f**king sweet
      }
    },
    {
      enabled: true,
      name: "Fiona Hughes",
      course: "BESS, 1st year",
      message: %Q{
just syncing it now 👍 thanks... so handy!
      }
    },
    {
      enabled: true,
      name: "Patrick Maher",
      course: "Sociology and Social Policy, 2nd year",
      message: %Q{
unbelievably handy
      }
    },
    {
      enabled: true,
      name: "Cian Flynn",
      course: "Engineering, 2nd year",
      message: %Q{
TCal is dead handy
      }
    },
    {
      enabled: true,
      name: "Aaron McDermott",
      course: "Business and German, 2nd year",
      message: %Q{
I actually turn up to lectures on time
      }
    },
    {
      enabled: true,
      name: "Conor Totterdell",
      course: "BESS, 2nd year",
      message: %Q{
Mind=Blown.
      }
    },
    {
      enabled: true,
      name: "Conor Totterdell",
      course: "Maths and Economics, 1st year",
      message: %Q{
An absolute godsend
      }
    },
  ]

  STANDARD_LIST = LIST.select { |t| t[:enabled] == true }.freeze
  ADMIN_LIST = LIST.select { |t| t[:enabled] }.freeze

  def self.sample(n, user=nil)
    (user.try(:is_admin?) ? ADMIN_LIST : STANDARD_LIST).sample(n)
  end
end
