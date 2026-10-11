
extends Control

var money: int = 2000
var energy: int = 100
var day: int = 1
var job: String = "Unemployed"
var house_level: int = 0

var status_label: Label
var message_label: Label

func _ready() -> void:
    build_game_ui()
    update_ui()

func build_game_ui() -> void:
    var background := ColorRect.new()
    background.color = Color("#14251f")
    background.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )
    add_child(background)

    var panel := VBoxContainer.new()
    panel.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )
    panel.add_theme_constant_override("separation", 14)
    panel.add_theme_constant_override("margin_left", 24)
    panel.add_theme_constant_override("margin_top", 24)
    panel.add_theme_constant_override("margin_right", 24)
    panel.add_theme_constant_override("margin_bottom", 24)
    add_child(panel)

    var title := Label.new()
    title.text = "EKO LIFE SIM"
    title.add_theme_font_size_override("font_size", 32)
    panel.add_child(title)

    status_label = Label.new()
    panel.add_child(status_label)

    var hustle_button := Button.new()
    hustle_button.text = "Do Street Hustle"
    hustle_button.pressed.connect(do_hustle)
    panel.add_child(hustle_button)

    var job_button := Button.new()
    job_button.text = "Find a Job"
    job_button.pressed.connect(find_job)
    panel.add_child(job_button)

    var rest_button := Button.new()
    rest_button.text = "Rest and Recover"
    rest_button.pressed.connect(rest)
    panel.add_child(rest_button)

    var house_button := Button.new()
    house_button.text = "Upgrade Housing"
    house_button.pressed.connect(upgrade_house)
    panel.add_child(house_button)

    var travel_button := Button.new()
    travel_button.text = "Travel to Another State"
    travel_button.pressed.connect(travel)
    panel.add_child(travel_button)

    message_label = Label.new()
    message_label.text = "Welcome to Lagos. Build your future!"
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
    panel.add_child(message_label)

func update_ui() -> void:
    if not is_instance_valid(status_label):
        return

    var homes := [
        "No house",
        "Rented room",
        "Small apartment",
        "Lagos house",
        "Banana Island mansion"
    ]

    status_label.text = (
        "Day: %d\nCash: ₦%s\nEnergy: %d/100\nJob: %s\nHome: %s"
        % [
            day,
            format_money(money),
            energy,
            job,
            homes[clampi(house_level, 0, 4)]
        ]
    )

func format_money(amount: int) -> String:
    return "%d" % amount

func do_hustle() -> void:
    if energy < 15:
        message_label.text = "You are exhausted. Rest first."
        return

    var earnings := randi_range(500, 2500)
    money += earnings
    energy -= 15
    message_label.text = (
        "You completed a street hustle and earned ₦%s."
        % format_money(earnings)
    )
    update_ui()

func find_job() -> void:
    if job == "Unemployed":
        job = "Shop Assistant"
        money += 1000
        message_label.text = (
            "You got a job as a shop assistant! "
            + "You received ₦1,000."
        )
    else:
        message_label.text = "You already have a job."

    update_ui()

func rest() -> void:
    energy = mini(100, energy + 40)
    day += 1

    if job != "Unemployed":
        money += 3000
        message_label.text = (
            "A new day begins. Your job paid ₦3,000."
        )
    else:
        message_label.text = "You rested and recovered energy."

    update_ui()

func upgrade_house() -> void:
    var prices := [5000, 20000, 100000, 1000000]

    if house_level >= 4:
        message_label.text = "You already own the top-tier home!"
        return

    var price: int = prices[house_level]

    if money < price:
        message_label.text = (
            "You need ₦%s for the next housing upgrade."
            % format_money(price)
        )
        return

    money -= price
    house_level += 1
    message_label.text = "Congratulations! You upgraded your home."
    update_ui()

func travel() -> void:
    var states := [
        "Lagos", "Ogun", "Oyo", "Osun", "Ondo",
        "Ekiti", "Kwara", "Edo", "Delta", "Rivers",
        "Enugu", "Anambra", "Abia", "Imo", "Bayelsa",
        "Akwa Ibom", "Cross River", "Benue", "Kogi",
        "Nasarawa", "Plateau", "Taraba", "Adamawa",
        "Gombe", "Bauchi", "Borno", "Yobe", "Jigawa",
        "Kano", "Katsina", "Kaduna", "Zamfara",
        "Sokoto", "Kebbi", "Niger", "FCT Abuja"
    ]

    var destination: String = states[
        randi_range(0, states.size() - 1)
    ]

    if money < 500:
        message_label.text = "You need ₦500 to travel."
        return

    money -= 500
    message_label.text = "You travelled to %s!" % destination
    update_ui()
