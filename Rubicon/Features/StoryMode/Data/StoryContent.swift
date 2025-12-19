import Foundation
import RubiconEngine

// MARK: - Story Content

struct StoryContent {
    static let chapters: [StoryChapter] = [
        chapter1,
        chapter2,
        chapter3,
        chapter4,
        chapter5,
        chapter6,
        chapter7,
        chapter8
    ]

    static func chapter(for id: Int) -> StoryChapter? {
        chapters.first { $0.id == id }
    }

    // MARK: - Chapter 1: First Steps

    static let chapter1 = StoryChapter(
        id: 1,
        title: "First Steps",
        subtitle: "The tournament begins",
        opponent: .luna,
        difficulty: .easy,
        location: "Tournament Hall",
        backgroundImage: "tournament_hall",
        preMatchDialogue: [
            .narration("The roar of the crowd fades as Kai steps through the towering glass doors of the World Championship arena."),
            DialogueEntry(speaker: .kai, text: "Three years of grinding online matches. Thousands of hours studying patterns. And now... I'm actually here."),
            .narration("A girl with silver hair blocks his path, her holographic glasses reflecting streams of data."),
            DialogueEntry(speaker: .luna, text: "You're Kai Morrow. The nobody who fluked his way through the qualifiers."),
            DialogueEntry(speaker: .kai, text: "And you're Luna Chen. Three-time junior champion. Your speed records are still unbroken."),
            DialogueEntry(speaker: .luna, text: "Flattery won't save you. I've been playing since before you knew this game existed. My win rate against qualifiers? One hundred percent."),
            DialogueEntry(speaker: .kai, text: "There's a first time for everything."),
            DialogueEntry(speaker: .luna, text: "Confidence. I like that. It'll make crushing you so much more satisfying. Fifteen moves. That's all I need."),
            DialogueEntry(speaker: .kai, text: "Then let's not waste time talking.")
        ],
        midMatchDialogue: [
            DialogueEntry(speaker: .luna, text: "What? You locked before me? That's... that's impossible!", triggersAt: .firstLock),
            DialogueEntry(speaker: .kai, text: "Impossible? Or just unexpected?"),
            DialogueEntry(speaker: .luna, text: "Don't get cocky. One lock means nothing!")
        ],
        postMatchDialogue: [
            DialogueEntry(speaker: .luna, text: "No... NO! This can't be happening!"),
            DialogueEntry(speaker: .kai, text: "You were so focused on speed, you forgot to watch the whole board."),
            DialogueEntry(speaker: .luna, text: "You got lucky. That's all this was. Luck!"),
            DialogueEntry(speaker: .kai, text: "Maybe. Or maybe you underestimated me."),
            DialogueEntry(speaker: .luna, text: "Marcus Webb is next. He doesn't make mistakes. He'll tear you apart with pure mathematics."),
            .narration("Luna storms off. In the shadows, an older man with a scarred face watches Kai intently before disappearing into the crowd.")
        ]
    )

    // MARK: - Chapter 2: The Numbers Game

    static let chapter2 = StoryChapter(
        id: 2,
        title: "The Numbers Game",
        subtitle: "Data versus instinct",
        opponent: .marcus,
        difficulty: .easy,
        location: "Analysis Room",
        backgroundImage: "analysis_room",
        preMatchDialogue: [
            .narration("Holographic screens fill the room with cascading data. Marcus Webb doesn't look up from his tablet."),
            DialogueEntry(speaker: .marcus, text: "Kai Morrow. Win rate: seventy-three point two percent. Average game length: twenty-four moves. Preferred opening: left-side control."),
            DialogueEntry(speaker: .kai, text: "You've been watching me."),
            DialogueEntry(speaker: .marcus, text: "I watch everyone. Data never lies. Your victory against Luna was a twelve percent probability event. Statistical noise."),
            DialogueEntry(speaker: .kai, text: "People aren't statistics, Marcus."),
            DialogueEntry(speaker: .marcus, text: "Everything is statistics. Your so-called intuition? Pattern recognition you're too slow to consciously process. I've already processed it all."),
            DialogueEntry(speaker: .kai, text: "And what do your numbers say about this match?"),
            DialogueEntry(speaker: .marcus, text: "My victory probability: eighty-nine point three percent. Margin of error: irrelevant."),
            DialogueEntry(speaker: .kai, text: "Then you've got nothing to worry about.")
        ],
        midMatchDialogue: [
            DialogueEntry(speaker: .marcus, text: "That move... it's not in your historical data. It defies your established patterns.", triggersAt: .midMatch),
            DialogueEntry(speaker: .kai, text: "I'm learning to surprise myself."),
            DialogueEntry(speaker: .marcus, text: "Impossible. You can't just... change who you are mid-game.")
        ],
        postMatchDialogue: [
            DialogueEntry(speaker: .marcus, text: "Error. Critical error. My models were flawless..."),
            DialogueEntry(speaker: .kai, text: "That's the thing about people. We grow. We adapt. We can't be reduced to numbers."),
            DialogueEntry(speaker: .marcus, text: "Perhaps... there are variables I failed to account for. You're an anomaly, Morrow."),
            DialogueEntry(speaker: .kai, text: "I'll take that as a compliment."),
            .narration("As Marcus leaves, Kai notices a strange symbol on his tablet. An ancient pattern that looks almost like... a Cross."),
            DialogueEntry(speaker: .marcus, text: "The others won't fall so easily. Especially not Yuki. She sees things the rest of us can't.")
        ]
    )

    // MARK: - Chapter 3: Art of War

    static let chapter3 = StoryChapter(
        id: 3,
        title: "Art of War",
        subtitle: "Beauty in strategy",
        opponent: .yuki,
        difficulty: .medium,
        location: "Garden Terrace",
        backgroundImage: "garden_terrace",
        preMatchDialogue: [
            .narration("Cherry blossoms drift through the air. Yuki Tanaka stands motionless beside a ancient bonsai, her eyes closed."),
            DialogueEntry(speaker: .yuki, text: "I watched your matches. Luna played like a tempest. Marcus, like a machine. But you..."),
            DialogueEntry(speaker: .kai, text: "Let me guess. I played like an amateur?"),
            DialogueEntry(speaker: .yuki, text: "You played like water. Flowing. Adapting. Taking the shape of whatever contains you."),
            DialogueEntry(speaker: .kai, text: "That's... actually kind of beautiful."),
            DialogueEntry(speaker: .yuki, text: "It's not entirely praise. Water has no form of its own. A true master shapes the vessel."),
            DialogueEntry(speaker: .kai, text: "You see this game differently, don't you?"),
            DialogueEntry(speaker: .yuki, text: "The board is a canvas. Every stone is a brushstroke. The patterns we form... they're expressions of our souls."),
            DialogueEntry(speaker: .kai, text: "Some people say the patterns have actual power. Ancient origins."),
            DialogueEntry(speaker: .yuki, text: "Dr. Okonkwo believes that. She's found texts. Evidence. Perhaps she's right. Perhaps the beauty I see is something more."),
            DialogueEntry(speaker: .kai, text: "What do you believe?"),
            DialogueEntry(speaker: .yuki, text: "I believe we're about to create something extraordinary. Shall we begin?")
        ],
        midMatchDialogue: [
            DialogueEntry(speaker: .yuki, text: "Magnificent! Do you see how our stones dance together? Even as rivals, we create art.", triggersAt: .midMatch),
            DialogueEntry(speaker: .kai, text: "It is beautiful. But I still intend to win."),
            DialogueEntry(speaker: .yuki, text: "Of course. The beauty is in the struggle itself.")
        ],
        postMatchDialogue: [
            DialogueEntry(speaker: .yuki, text: "The water has begun carving its own path. You've grown, Kai."),
            DialogueEntry(speaker: .kai, text: "Thank you. For treating this as more than just competition."),
            DialogueEntry(speaker: .yuki, text: "It was always more. Viktor waits for you in the next round. He was champion once, before something broke him."),
            .narration("Yuki presses a small pendant into Kai's palm. It's shaped like a Gate pattern, carved from ancient stone."),
            DialogueEntry(speaker: .yuki, text: "For protection. You'll need it where you're going."),
            DialogueEntry(speaker: .kai, text: "Where am I going?"),
            DialogueEntry(speaker: .yuki, text: "Deeper than you know.")
        ]
    )

    // MARK: - Chapter 4: Scars of Glory

    static let chapter4 = StoryChapter(
        id: 4,
        title: "Scars of Glory",
        subtitle: "A champion's burden",
        opponent: .viktor,
        difficulty: .medium,
        location: "Locker Room",
        backgroundImage: "locker_room",
        preMatchDialogue: [
            .narration("The locker room is dark save for a single lamp. Viktor Kross sits alone, clutching a tarnished trophy."),
            DialogueEntry(speaker: .kai, text: "Viktor Kross. You were world champion when I was still learning to walk."),
            DialogueEntry(speaker: .viktor, text: "Was. That's the word that matters. Fifteen years ago, I was untouchable. Now I'm a ghost story they tell rookies."),
            DialogueEntry(speaker: .kai, text: "What happened to you?"),
            DialogueEntry(speaker: .viktor, text: "I saw something. Felt something. The patterns... they're not just strategy, boy. They're alive. And I wasn't ready."),
            DialogueEntry(speaker: .kai, text: "You're talking about the resonance. Others have mentioned it."),
            DialogueEntry(speaker: .viktor, text: "You've felt it too. I can see it in your eyes. The way the stones sing to you."),
            DialogueEntry(speaker: .kai, text: "I don't understand what's happening to me."),
            DialogueEntry(speaker: .viktor, text: "Neither did I. That's why I ran. But you... you're different. Stronger. Maybe strong enough."),
            DialogueEntry(speaker: .kai, text: "Strong enough for what?"),
            DialogueEntry(speaker: .viktor, text: "To face what I couldn't. Now play me. Show me I wasn't wrong about you!")
        ],
        midMatchDialogue: [
            DialogueEntry(speaker: .viktor, text: "THERE! Feel that? The stones are resonating! They want to form the Cross!", triggersAt: .midMatch),
            DialogueEntry(speaker: .kai, text: "Viktor, you're scaring me."),
            DialogueEntry(speaker: .viktor, text: "Good! Fear means you're paying attention! Keep playing!")
        ],
        postMatchDialogue: [
            DialogueEntry(speaker: .viktor, text: "Yes... YES! The resonance chose you. I can see it now."),
            DialogueEntry(speaker: .kai, text: "Please, Viktor. Explain what's happening."),
            DialogueEntry(speaker: .viktor, text: "I can't. I only glimpsed the truth before terror consumed me. But Amara... she's devoted her life to understanding."),
            .narration("Viktor removes a signet ring, ancient and heavy, engraved with a Line pattern."),
            DialogueEntry(speaker: .viktor, text: "I took this from a temple in Morocco. It started everything. Give it to her. Tell her... Viktor remembers."),
            DialogueEntry(speaker: .kai, text: "Remembers what?"),
            DialogueEntry(speaker: .viktor, text: "That some things are worth being afraid of.")
        ]
    )

    // MARK: - Chapter 5: Ancient Truths

    static let chapter5 = StoryChapter(
        id: 5,
        title: "Ancient Truths",
        subtitle: "The patterns revealed",
        opponent: .amara,
        difficulty: .hard,
        location: "University Library",
        backgroundImage: "university_library",
        preMatchDialogue: [
            .narration("Ancient manuscripts line the walls. Dr. Okonkwo stands before a massive diagram of interlocking patterns."),
            DialogueEntry(speaker: .amara, text: "Kai Morrow. Viktor told me you'd come. And you've brought his ring."),
            DialogueEntry(speaker: .kai, text: "He said you know the truth. About the patterns. About what's happening in this tournament."),
            DialogueEntry(speaker: .amara, text: "What do you know about history?"),
            DialogueEntry(speaker: .kai, text: "I know Rubicon is just a board game."),
            DialogueEntry(speaker: .amara, text: "It's three thousand years old. Born in ancient Mesopotamia, carried through Egypt, Greece, Rome. The patterns... they're not strategy. They're sacred geometry. Maps of consciousness itself."),
            DialogueEntry(speaker: .kai, text: "That sounds impossible."),
            DialogueEntry(speaker: .amara, text: "I thought so too. Until I found the texts. The ancient masters didn't just play this game. They used it to transcend. To become something more."),
            DialogueEntry(speaker: .kai, text: "The Grandmaster. Ishara. Are they part of this?"),
            DialogueEntry(speaker: .amara, text: "Seven years undefeated. No one knows their age, origin, or true name. I believe Ishara has fully awakened what the game offers."),
            DialogueEntry(speaker: .kai, text: "Which is?"),
            DialogueEntry(speaker: .amara, text: "Immortality, perhaps. Or something beyond our understanding. Now... let me see if you're ready to learn more.")
        ],
        midMatchDialogue: [
            DialogueEntry(speaker: .amara, text: "Yes! You're seeing it now! The patterns forming before you place the stones!", triggersAt: .midMatch),
            DialogueEntry(speaker: .kai, text: "It's like... I can feel where the game wants to go."),
            DialogueEntry(speaker: .amara, text: "That's the resonance awakening. Trust it. Let it guide you.")
        ],
        postMatchDialogue: [
            DialogueEntry(speaker: .amara, text: "You've passed the examination. You're ready for the Twins."),
            DialogueEntry(speaker: .kai, text: "Ren and Sora? What makes them different?"),
            DialogueEntry(speaker: .amara, text: "They share a bond beyond ordinary comprehension. Two bodies, one consciousness. They've touched the deepest level of resonance."),
            DialogueEntry(speaker: .kai, text: "How do you defeat two minds working as one?"),
            DialogueEntry(speaker: .amara, text: "By becoming something greater. Remember, Kai... the game was never about defeating opponents. It's about transformation. That's what crossing the Rubicon truly means."),
            DialogueEntry(speaker: .kai, text: "Transformation into what?"),
            DialogueEntry(speaker: .amara, text: "That's what you're about to discover.")
        ]
    )

    // MARK: - Chapter 6: Mirror Match

    static let chapter6 = StoryChapter(
        id: 6,
        title: "Mirror Match",
        subtitle: "Two minds, one game",
        opponent: .ren,
        difficulty: .hard,
        location: "Empty Stadium",
        backgroundImage: "empty_stadium",
        preMatchDialogue: [
            .narration("A single spotlight illuminates the board. Two figures stand motionless. One dressed in white. One in black."),
            DialogueEntry(speaker: .ren, text: "You've come far, Kai Morrow."),
            DialogueEntry(speaker: .sora, text: "Farther than most dare to travel."),
            DialogueEntry(speaker: .ren, text: "Viktor shattered."),
            DialogueEntry(speaker: .sora, text: "Luna fled."),
            DialogueEntry(speaker: .ren, text: "Marcus doubted."),
            DialogueEntry(speaker: .sora, text: "But you..."),
            DialogueEntry(speaker: .ren, text: "...adapted."),
            DialogueEntry(speaker: .kai, text: "Can you stop doing that? The twin thing is deeply unsettling."),
            DialogueEntry(speaker: .sora, text: "We don't finish each other's sentences."),
            DialogueEntry(speaker: .ren, text: "We share the same thought."),
            DialogueEntry(speaker: .sora, text: "Since birth, we've been two halves of one whole."),
            DialogueEntry(speaker: .ren, text: "The game taught us to embrace our bond."),
            DialogueEntry(speaker: .kai, text: "How is that even possible?"),
            DialogueEntry(speaker: .sora, text: "The same way you feel the resonance."),
            DialogueEntry(speaker: .ren, text: "Connection. Unity. The patterns reveal that separation is illusion."),
            DialogueEntry(speaker: .sora, text: "Defeat us..."),
            DialogueEntry(speaker: .ren, text: "...and you'll understand.")
        ],
        midMatchDialogue: [
            DialogueEntry(speaker: .kai, text: "Wait... you're both moving stones? That can't be legal!", triggersAt: .midMatch),
            DialogueEntry(speaker: .ren, text: "One mind."),
            DialogueEntry(speaker: .sora, text: "Two hands."),
            DialogueEntry(speaker: .ren, text: "The rules govern players."),
            DialogueEntry(speaker: .sora, text: "Not consciousness."),
            DialogueEntry(speaker: .kai, text: "This is madness...")
        ],
        postMatchDialogue: [
            .narration("The twins bow in perfect synchronization."),
            DialogueEntry(speaker: .ren, text: "You found the space between thoughts."),
            DialogueEntry(speaker: .sora, text: "Where strategy dissolves into pure intuition."),
            DialogueEntry(speaker: .kai, text: "I don't know how I did it. It felt like... I was playing with the game itself."),
            DialogueEntry(speaker: .ren, text: "Twenty years we've played as one."),
            DialogueEntry(speaker: .sora, text: "No one has ever defeated our shared mind."),
            DialogueEntry(speaker: .ren, text: "Elias warned us this day would come."),
            DialogueEntry(speaker: .sora, text: "The Ghost sees further than anyone."),
            DialogueEntry(speaker: .kai, text: "You know Elias Crane?"),
            .narration("The lights begin to fade. The twins step backward into darkness."),
            DialogueEntry(speaker: .ren, text: "Everyone who crosses the Rubicon..."),
            DialogueEntry(speaker: .sora, text: "...knows the Ghost.")
        ]
    )

    // MARK: - Chapter 7: The Ghost's Gambit

    static let chapter7 = StoryChapter(
        id: 7,
        title: "The Ghost's Gambit",
        subtitle: "Shadows of the past",
        opponent: .elias,
        difficulty: .expert,
        location: "Ancient Chamber",
        backgroundImage: "ancient_chamber",
        preMatchDialogue: [
            .narration("Stone walls covered with carved game boards. Torches flicker in an underground chamber older than history."),
            DialogueEntry(speaker: .kai, text: "Elias Crane. The Ghost. You vanished from competition twenty years ago."),
            DialogueEntry(speaker: .elias, text: "Because you're the first, Kai. The first in two decades who might be worthy."),
            DialogueEntry(speaker: .kai, text: "Worthy of what?"),
            DialogueEntry(speaker: .elias, text: "Of facing Ishara. Of surviving what lies beyond. I was like you once. Young. Brilliant. Hungry. I won six world championships. Then came my match with Ishara."),
            DialogueEntry(speaker: .kai, text: "What happened?"),
            DialogueEntry(speaker: .elias, text: "I lost. Not just the game. Ishara showed me what the patterns truly are. What they can unlock. It terrified me beyond reason."),
            DialogueEntry(speaker: .kai, text: "You ran."),
            DialogueEntry(speaker: .elias, text: "I fled. Hid. Became the ghost they whisper about. But I never stopped watching. Waiting for someone strong enough to succeed where I failed."),
            DialogueEntry(speaker: .kai, text: "And you think that's me."),
            DialogueEntry(speaker: .elias, text: "I know it is. You carry Viktor's ring. Yuki's pendant. The Twins' blessing. But you're still missing one thing."),
            DialogueEntry(speaker: .kai, text: "What?"),
            DialogueEntry(speaker: .elias, text: "The courage to lose everything. If you can't face what I'm about to show you, leave now. Return to your ordinary life. There's no shame in survival."),
            DialogueEntry(speaker: .kai, text: "I didn't come this far to turn back."),
            DialogueEntry(speaker: .elias, text: "Then prove it.")
        ],
        midMatchDialogue: [
            DialogueEntry(speaker: .elias, text: "Do you hear that? The stones are singing. They haven't sung like this since I faced Ishara.", triggersAt: .midMatch),
            DialogueEntry(speaker: .kai, text: "I see them. Patterns that haven't been placed yet. Futures branching from every move."),
            DialogueEntry(speaker: .elias, text: "That's the gift, Kai. And the curse. Once you see, you can never unsee."),
            DialogueEntry(speaker: .kai, text: "I'm not afraid."),
            DialogueEntry(speaker: .elias, text: "You should be.")
        ],
        postMatchDialogue: [
            .narration("Light fills the ancient chamber. Elias falls to his knees."),
            DialogueEntry(speaker: .elias, text: "Twenty years. Twenty years I've waited to lose this match."),
            DialogueEntry(speaker: .kai, text: "You wanted to lose?"),
            DialogueEntry(speaker: .elias, text: "Losing to you means the game continues. Means I wasn't the end of the line."),
            DialogueEntry(speaker: .kai, text: "Elias... after I face Ishara... will I still be me?"),
            DialogueEntry(speaker: .elias, text: "You'll be more. That's the entire point. That's always been the point."),
            .narration("Elias rises, but his form seems to flicker like candlelight."),
            DialogueEntry(speaker: .elias, text: "We'll be watching, Kai. All of us who crossed the Rubicon. Win or lose... you're one of us now."),
            DialogueEntry(speaker: .kai, text: "What happens next?"),
            DialogueEntry(speaker: .elias, text: "Ishara waits in the Grand Hall. They've always known you were coming. Now go. Finish what we all started.")
        ]
    )

    // MARK: - Chapter 8: Crossing the Rubicon

    static let chapter8 = StoryChapter(
        id: 8,
        title: "Crossing the Rubicon",
        subtitle: "The final game",
        opponent: .ishara,
        difficulty: .master,
        location: "The Grand Hall",
        backgroundImage: "grand_hall",
        preMatchDialogue: [
            .narration("Reality bends. Ancient columns stretch into infinity. Stones float in defiance of gravity. Ishara sits at a board made of pure light."),
            DialogueEntry(speaker: .ishara, text: "Kai Morrow. Slayer of the Prodigy. Breaker of the Analyst. Student of the Artist. Heir to the Veteran. Pupil of the Scholar. Victor over the Mirrors. Successor to the Ghost."),
            DialogueEntry(speaker: .kai, text: "You know everything that's happened."),
            DialogueEntry(speaker: .ishara, text: "I've watched your entire journey. Every match. Every doubt. Every awakening."),
            DialogueEntry(speaker: .kai, text: "Then you know why I'm here."),
            DialogueEntry(speaker: .ishara, text: "You seek answers. Truth. Purpose. You want to understand what the patterns really are."),
            DialogueEntry(speaker: .kai, text: "Are you even human?"),
            DialogueEntry(speaker: .ishara, text: "I was. Once. Seven hundred years ago. The game transformed me. Made me its guardian."),
            DialogueEntry(speaker: .kai, text: "That's impossible."),
            DialogueEntry(speaker: .ishara, text: "You've felt the resonance. Seen time bend around the patterns. You know nothing is impossible."),
            DialogueEntry(speaker: .kai, text: "What happens if I win?"),
            DialogueEntry(speaker: .ishara, text: "You take my place. Become the next guardian. Join those of us who have transcended mortality."),
            DialogueEntry(speaker: .kai, text: "And if I lose?"),
            DialogueEntry(speaker: .ishara, text: "You return to your life, forever changed by what you've learned. Either way, you will never be the same."),
            .narration("The board ignites. Stones rise into the air, orbiting like planets."),
            DialogueEntry(speaker: .ishara, text: "One final game, Kai Morrow. Not for glory. Not for victory. For evolution. Show me everything you've become.")
        ],
        midMatchDialogue: [
            DialogueEntry(speaker: .ishara, text: "Magnificent. You're no longer playing with strategy. You're playing with spirit. With soul.", triggersAt: .midMatch),
            DialogueEntry(speaker: .kai, text: "I understand now. Everything. The game was never about winning. It's about transformation."),
            DialogueEntry(speaker: .ishara, text: "The Line teaches focus. The Bend teaches adaptation. The Gate teaches protection. The Cross teaches transcendence."),
            DialogueEntry(speaker: .kai, text: "And crossing the Rubicon..."),
            DialogueEntry(speaker: .ishara, text: "Teaches us there's no returning to who we were."),
            DialogueEntry(speaker: .kai, text: "I'm ready."),
            DialogueEntry(speaker: .ishara, text: "Then finish it. Complete the pattern. Become what you were always meant to be.")
        ],
        postMatchDialogue: [
            .narration("Light explodes from the board. The universe holds its breath. Kai rises, transformed."),
            DialogueEntry(speaker: .ishara, text: "It is done. After seven centuries... I am free."),
            DialogueEntry(speaker: .kai, text: "You waited seven hundred years for this moment?"),
            DialogueEntry(speaker: .ishara, text: "Waiting for someone worthy. Someone strong enough to carry the flame. And now..."),
            .narration("Ishara begins to dissolve into pure radiance."),
            DialogueEntry(speaker: .ishara, text: "The game is yours, Kai Morrow. Guard it well. Teach those who seek truth. And when the next worthy challenger comes..."),
            DialogueEntry(speaker: .kai, text: "I'll be ready. Just as you were."),
            DialogueEntry(speaker: .ishara, text: "You understand at last. Welcome to eternity, Guardian. May your patterns always find their form."),
            .narration("Ishara becomes light, becomes nothing, becomes everything. Kai stands alone in the Grand Hall... immortal, eternal, transformed. The new master of the Rubicon."),
            DialogueEntry(speaker: .kai, text: "I understand now. I finally understand."),
            .narration("And somewhere in the world, a young player sits down to their first match, unaware of the journey that awaits them...")
        ]
    )
}
